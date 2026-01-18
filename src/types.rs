use godot::prelude::*;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Mutex, OnceLock};

/// Global debug-mode flag
static DEBUG_MODE: AtomicBool = AtomicBool::new(false);

/// Thread-safe log queue to funnel background-thread logs to the Godot main thread
static LOG_QUEUE: OnceLock<Mutex<Vec<(LogLevel, String)>>> = OnceLock::new();

/// Enable or disable debug mode
pub fn set_debug_mode(enabled: bool) {
    DEBUG_MODE.store(enabled, Ordering::Relaxed);
}

/// Check whether debug mode is enabled
pub fn is_debug_mode() -> bool {
    DEBUG_MODE.load(Ordering::Relaxed)
}

/// Log level for queued BLE logs
#[derive(Clone, Copy)]
pub enum LogLevel {
    Debug,
    Info,
    Warn,
    Error,
}

fn log_queue() -> &'static Mutex<Vec<(LogLevel, String)>> {
    LOG_QUEUE.get_or_init(|| Mutex::new(Vec::new()))
}

pub fn enqueue_log(level: LogLevel, message: String) {
    if let Ok(mut queue) = log_queue().lock() {
        queue.push((level, message));
    }
}

/// Drain queued logs (to be called from the Godot main thread)
pub fn drain_logs() -> Vec<(LogLevel, String)> {
    let mut out = Vec::new();
    if let Ok(mut queue) = log_queue().lock() {
        std::mem::swap(&mut *queue, &mut out);
    }
    out
}

/// Debug log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_debug {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            $crate::types::enqueue_log($crate::types::LogLevel::Debug, format!($($arg)*));
        }
    };
}

/// Info log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_info {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            $crate::types::enqueue_log($crate::types::LogLevel::Info, format!($($arg)*));
        }
    };
}

/// Warning log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_warn {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            $crate::types::enqueue_log($crate::types::LogLevel::Warn, format!($($arg)*));
        }
    };
}

/// Error log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_error {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            $crate::types::enqueue_log($crate::types::LogLevel::Error, format!($($arg)*));
        }
    };
}

/// Device info structure
#[derive(Clone, Debug)]
pub struct DeviceInfo {
    pub address: String,
    pub name: Option<String>,
    pub rssi: Option<i16>,
    pub services: Vec<String>,
    pub manufacturer_data: std::collections::HashMap<u16, Vec<u8>>,
    pub service_data: std::collections::HashMap<String, Vec<u8>>,
    pub tx_power_level: Option<i16>,
}

impl DeviceInfo {
    /// Construct a new device info record
    pub fn new(
        address: String, 
        name: Option<String>, 
        rssi: Option<i16>,
        services: Vec<String>,
        manufacturer_data: std::collections::HashMap<u16, Vec<u8>>,
        service_data: std::collections::HashMap<String, Vec<u8>>,
        tx_power_level: Option<i16>,
    ) -> Self {
        Self {
            address,
            name,
            rssi,
            services,
            manufacturer_data,
            service_data,
            tx_power_level,
        }
    }

    /// Convert to a Godot VarDictionary
    pub fn to_dictionary(&self) -> VarDictionary {
        let mut dict = VarDictionary::new();
        dict.set("address", self.address.clone());

        if let Some(ref name) = self.name {
            dict.set("name", name.clone());
        }

        if let Some(rssi) = self.rssi {
            dict.set("rssi", rssi);
        }

        // Services
        let mut services_array: Array<GString> = Array::new();
        for service in &self.services {
            services_array.push(&GString::from(service));
        }
        dict.set("services", services_array);

        // Manufacturer Data
        let mut manuf_dict = VarDictionary::new();
        for (id, data) in &self.manufacturer_data {
            let mut byte_array = PackedByteArray::new();
            for byte in data {
                byte_array.push(*byte);
            }
            manuf_dict.set(*id, byte_array);
        }
        dict.set("manufacturer_data", manuf_dict);

        // Service Data
        let mut service_data_dict = VarDictionary::new();
        for (uuid_str, data) in &self.service_data {
            let mut byte_array = PackedByteArray::new();
            for byte in data {
                byte_array.push(*byte);
            }
            service_data_dict.set(GString::from(uuid_str), byte_array);
        }
        dict.set("service_data", service_data_dict);

        // TX Power Level
        if let Some(tx) = self.tx_power_level {
            dict.set("tx_power_level", tx);
        }
        
        dict
    }
}

/// BLE error types
#[derive(Debug, Clone)]
pub enum BleError {
    /// Bluetooth adapter not found
    AdapterNotFound,
    /// Device not found
    DeviceNotFound(String),
    /// Connection failed
    ConnectionFailed(String),
    /// Operation failed
    OperationFailed(String),
    /// Device not connected
    NotConnected,
    /// Invalid UUID
    InvalidUuid(String),
    /// Service not found
    ServiceNotFound(String),
    /// Characteristic not found
    CharacteristicNotFound(String),
    /// Scan failed
    ScanFailed(String),
    /// Initialization failed
    InitializationFailed(String),
    /// Read failed
    ReadFailed(String),
    /// Write failed
    WriteFailed(String),
    /// Subscription failed
    SubscribeFailed(String),
    /// Unsubscribe failed
    UnsubscribeFailed(String),
    /// Service discovery failed
    ServiceDiscoveryFailed(String),
    /// Permission denied
    PermissionDenied(String),
    /// Timeout
    Timeout(String),
    /// Internal error
    InternalError(String),
}

impl BleError {
    /// Convert to GString (for Godot signals)
    pub fn to_gstring(&self) -> GString {
        GString::from(self.to_string().as_str())
    }

    /// Convert to a human-readable string
    pub fn to_string(&self) -> String {
        match self {
            BleError::AdapterNotFound => {
                "Bluetooth adapter not found; ensure system Bluetooth is enabled".to_string()
            }
            BleError::DeviceNotFound(addr) => {
                format!("Unable to find the specified Bluetooth device: {}", addr)
            }
            BleError::ConnectionFailed(msg) => {
                format!("Connection failed: {}", msg)
            }
            BleError::OperationFailed(msg) => {
                format!("Operation failed: {}", msg)
            }
            BleError::NotConnected => {
                "Device is not connected; connect the device first".to_string()
            }
            BleError::InvalidUuid(uuid) => {
                format!("Invalid UUID: {}", uuid)
            }
            BleError::ServiceNotFound(uuid) => {
                format!("Service UUID not found: {}", uuid)
            }
            BleError::CharacteristicNotFound(uuid) => {
                format!("Characteristic UUID not found: {}", uuid)
            }
            BleError::ScanFailed(msg) => {
                format!("Scan failed: {}", msg)
            }
            BleError::InitializationFailed(msg) => {
                format!("Initialization failed: {}", msg)
            }
            BleError::ReadFailed(msg) => {
                format!("Characteristic read failed: {}", msg)
            }
            BleError::WriteFailed(msg) => {
                format!("Characteristic write failed: {}", msg)
            }
            BleError::SubscribeFailed(msg) => {
                format!("Subscription to notifications failed: {}", msg)
            }
            BleError::UnsubscribeFailed(msg) => {
                format!("Unsubscribe failed: {}", msg)
            }
            BleError::ServiceDiscoveryFailed(msg) => {
                format!("Service discovery failed: {}", msg)
            }
            BleError::PermissionDenied(msg) => {
                format!("Permission denied: {}", msg)
            }
            BleError::Timeout(msg) => {
                format!("Operation timed out: {}", msg)
            }
            BleError::InternalError(msg) => {
                format!("Internal error: {}", msg)
            }
        }
    }

    /// Return the symbolic error code
    pub fn error_code(&self) -> &str {
        match self {
            BleError::AdapterNotFound => "ADAPTER_NOT_FOUND",
            BleError::DeviceNotFound(_) => "DEVICE_NOT_FOUND",
            BleError::ConnectionFailed(_) => "CONNECTION_FAILED",
            BleError::OperationFailed(_) => "OPERATION_FAILED",
            BleError::NotConnected => "NOT_CONNECTED",
            BleError::InvalidUuid(_) => "INVALID_UUID",
            BleError::ServiceNotFound(_) => "SERVICE_NOT_FOUND",
            BleError::CharacteristicNotFound(_) => "CHARACTERISTIC_NOT_FOUND",
            BleError::ScanFailed(_) => "SCAN_FAILED",
            BleError::InitializationFailed(_) => "INITIALIZATION_FAILED",
            BleError::ReadFailed(_) => "READ_FAILED",
            BleError::WriteFailed(_) => "WRITE_FAILED",
            BleError::SubscribeFailed(_) => "SUBSCRIBE_FAILED",
            BleError::UnsubscribeFailed(_) => "UNSUBSCRIBE_FAILED",
            BleError::ServiceDiscoveryFailed(_) => "SERVICE_DISCOVERY_FAILED",
            BleError::PermissionDenied(_) => "PERMISSION_DENIED",
            BleError::Timeout(_) => "TIMEOUT",
            BleError::InternalError(_) => "INTERNAL_ERROR",
        }
    }

    /// Indicate whether the error is retryable
    pub fn is_retryable(&self) -> bool {
        matches!(
            self,
            BleError::Timeout(_) | BleError::ConnectionFailed(_) | BleError::OperationFailed(_)
        )
    }

    /// Log the error to the Godot console
    pub fn log_error(&self) {
        enqueue_log(LogLevel::Error, format!("{}: {}", self.error_code(), self.to_string()));
    }

    /// Log a warning to the Godot console
    pub fn log_warning(&self) {
        enqueue_log(LogLevel::Warn, format!("{}: {}", self.error_code(), self.to_string()));
    }
}

impl std::fmt::Display for BleError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_string())
    }
}

impl std::error::Error for BleError {}

/// Adapter info structure
#[derive(Clone, Debug)]
pub struct AdapterInfo {
    pub name: String,
    pub address: Option<String>,
}

impl AdapterInfo {
    /// Construct a new adapter info record
    pub fn new(name: String, address: Option<String>) -> Self {
        Self { name, address }
    }

    /// Convert to a Godot VarDictionary
    pub fn to_dictionary(&self) -> VarDictionary {
        let mut dict = VarDictionary::new();
        dict.set("name", self.name.clone());
        
        if let Some(ref address) = self.address {
            dict.set("address", address.clone());
        } else {
            dict.set("address", Variant::nil());
        }
        
        dict
    }
}

// Re-export BLE service and characteristic types from their modules
// These are used by other modules but not directly in this file
#[allow(unused_imports)]
pub use crate::ble_characteristic::{BleCharacteristicInfo, CharacteristicProperties};
#[allow(unused_imports)]
pub use crate::ble_service::BleServiceInfo;
