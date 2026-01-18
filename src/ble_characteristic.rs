use godot::prelude::*;

/// Characteristic properties
#[derive(Clone, Debug)]
pub struct CharacteristicProperties {
    pub read: bool,
    pub write: bool,
    pub write_without_response: bool,
    pub notify: bool,
    pub indicate: bool,
}

impl CharacteristicProperties {
    /// Convert to a Godot Dictionary
    pub fn to_dictionary(&self) -> Dictionary {
        let mut dict = Dictionary::new();
        dict.set("read", self.read);
        dict.set("write", self.write);
        dict.set("write_without_response", self.write_without_response);
        dict.set("notify", self.notify);
        dict.set("indicate", self.indicate);
        dict
    }
}

/// BLE characteristic info
#[derive(Clone, Debug)]
pub struct BleCharacteristicInfo {
    pub uuid: String,
    pub properties: CharacteristicProperties,
}

impl BleCharacteristicInfo {
    /// Create a new characteristic info record
    pub fn new(uuid: String, properties: CharacteristicProperties) -> Self {
        Self { uuid, properties }
    }

    /// Convert to a Godot Dictionary
    pub fn to_dictionary(&self) -> Dictionary {
        let mut dict = Dictionary::new();
        dict.set("uuid", self.uuid.clone());
        dict.set("properties", self.properties.to_dictionary());
        dict
    }
}
