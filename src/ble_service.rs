use godot::prelude::*;
use crate::ble_characteristic::BleCharacteristicInfo;

/// BLE service info
#[derive(Clone, Debug)]
pub struct BleServiceInfo {
    pub uuid: String,
    pub characteristics: Vec<BleCharacteristicInfo>,
}

impl BleServiceInfo {
    /// Create a new service info record
    pub fn new(uuid: String, characteristics: Vec<BleCharacteristicInfo>) -> Self {
        Self {
            uuid,
            characteristics,
        }
    }

    /// Convert to a Godot Dictionary
    pub fn to_dictionary(&self) -> VarDictionary {
        let mut dict = VarDictionary::new();
        dict.set("uuid", self.uuid.clone());
        
        let chars_array: Array<VarDictionary> = self.characteristics
            .iter()
            .map(|char_info| char_info.to_dictionary())
            .collect();
        
        dict.set("characteristics", chars_array);
        
        dict
    }
}
