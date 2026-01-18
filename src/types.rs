use godot::prelude::*;
use std::sync::atomic::{AtomicBool, Ordering};

/// Global debug-mode flag
static DEBUG_MODE: AtomicBool = AtomicBool::new(false);

/// Enable or disable debug mode
pub fn set_debug_mode(enabled: bool) {
    DEBUG_MODE.store(enabled, Ordering::Relaxed);
}

/// Check whether debug mode is enabled
pub fn is_debug_mode() -> bool {
    DEBUG_MODE.load(Ordering::Relaxed)
}

/// Debug log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_debug {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            godot::prelude::godot_print!("[BLE Debug] {}", format!($($arg)*));
        }
    };
}

/// Info log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_info {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            godot::prelude::godot_print!("[BLE Info] {}", format!($($arg)*));
        }
    };
}

/// Warning log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_warn {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            godot::prelude::godot_warn!("[BLE Warning] {}", format!($($arg)*));
        }
    };
}

/// Error log macro (emits only when debug mode is on)
#[macro_export]
macro_rules! ble_error {
    ($($arg:tt)*) => {
        if $crate::types::is_debug_mode() {
            godot::prelude::godot_error!("[BLE Error] {}", format!($($arg)*));
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

    /// Convert to a Godot Dictionary
    pub fn to_dictionary(&self) -> Dictionary {
        let mut dict = Dictionary::new();
        dict.set("address", self.address.clone());
        
        if let Some(ref name) = self.name {
            dict.set("name", name.clone());
        } else {
            dict.set("name", Variant::nil());
        }
        
        if let Some(rssi) = self.rssi {
            dict.set("rssi", rssi);
        } else {
            dict.set("rssi", Variant::nil());
        }

        // Services
        let mut services_array: Array<GString> = Array::new();
        for service in &self.services {
            services_array.push(&GString::from(service));
        }
        dict.set("services", services_array);

        // Manufacturer Data
        let mut manuf_dict = Dictionary::new();
        for (id, data) in &self.manufacturer_data {
            let mut byte_array = PackedByteArray::new();
            for byte in data {
                byte_array.push(*byte);
            }
            manuf_dict.set(*id, byte_array);
        }
        dict.set("manufacturer_data", manuf_dict);

        // Service Data
        let mut service_data_dict = Dictionary::new();
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
        } else {
            dict.set("tx_power_level", Variant::nil());
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

    /// 获取错误代码
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

    /// 判断错误是否可重试
    pub fn is_retryable(&self) -> bool {
        matches!(
            self,
            BleError::Timeout(_) | BleError::ConnectionFailed(_) | BleError::OperationFailed(_)
        )
    }

    /// 记录错误到 Godot 控制台
    pub fn log_error(&self) {
        godot_error!("[BLE Error] {}: {}", self.error_code(), self.to_string());
    }

    /// 记录警告到 Godot 控制台
    pub fn log_warning(&self) {
        godot_warn!("[BLE Warning] {}: {}", self.error_code(), self.to_string());
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

    /// Convert to a Godot Dictionary
    pub fn to_dictionary(&self) -> Dictionary {
        let mut dict = Dictionary::new();
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
