extends Node

# Bluetooth plugin test script
# Demonstrates how to scan and connect to BLE devices with the GDBLE plugin

var bluetooth_manager: BluetoothManager
var connected_device: BleDevice = null
var start_scan_button: Button
var device_list: ItemList
var service_list: ItemList
var characteristic_list: ItemList
var address_to_index: Dictionary = {}
var adapter_ready := false
var scanning := false
var current_services: Array = []

func _ready():
	print("=== Bluetooth Plugin Test ===")
	start_scan_button = $Button
	device_list = $ItemList
	service_list = $ServiceList
	characteristic_list = $CharacteristicList
	start_scan_button.disabled = true
	start_scan_button.pressed.connect(_on_start_scan_pressed)
	device_list.item_selected.connect(_on_item_selected)
	service_list.item_selected.connect(_on_service_selected)
	characteristic_list.item_selected.connect(_on_characteristic_selected)

	# Create a BluetoothManager instance
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)
	
	# Wire up signals (only once during initialization)
	bluetooth_manager.adapter_initialized.connect(_on_adapter_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_discovered)
	bluetooth_manager.device_connected.connect(_on_device_connected)
	bluetooth_manager.device_disconnected.connect(_on_device_disconnected)
	bluetooth_manager.scan_started.connect(_on_scan_started)
	bluetooth_manager.scan_stopped.connect(_on_scan_stopped)
	bluetooth_manager.error_occurred.connect(_on_error_occurred)
	
	# Initialize the Bluetooth adapter
	print("Initializing Bluetooth adapter...")
	# Disable verbose debug output
	bluetooth_manager.set_debug_mode(false)
	bluetooth_manager.initialize()

func start_scanning():
	print("\n=== Starting BLE Scan ===")
	device_list.clear()
	address_to_index.clear()
	service_list.clear()
	characteristic_list.clear()
	current_services.clear()
	# Begin scanning (10 seconds)
	bluetooth_manager.start_scan(10.0)

func _on_start_scan_pressed():
	if not adapter_ready:
		print("Adapter not ready; cannot start scan yet")
		return
	if scanning:
		print("Scan already running; stopping previous scan")
		bluetooth_manager.stop_scan()
		return
	start_scan_button.disabled = true
	start_scanning()

func connect_to_device(address: String):
	print("\n=== Connecting to device: ", address, " ===")
	
	# Connect to the device via BluetoothManager
	var device = bluetooth_manager.connect_device(address)
	if device:
		print("Device instance created successfully")
		connected_device = device
		
		# Connect device signals
		print("Connecting device signals...")
		device.connected.connect(_on_device_connected_signal)
		device.disconnected.connect(_on_device_disconnected_signal)
		device.connection_failed.connect(_on_connection_failed)
		device.services_discovered.connect(_on_services_discovered)
		device.characteristic_read.connect(_on_characteristic_read)
		device.characteristic_written.connect(_on_characteristic_written)
		device.characteristic_notified.connect(_on_characteristic_notified)
		device.operation_failed.connect(_on_operation_failed)
		
		print("Signals connected, starting async connection...")
		# Start the connection
		device.connect_async()
		print("Connection process initiated")
	else:
		print("Failed to create device instance")

func discover_services():
	if connected_device:
		print("\n=== Discovering services ===")
		print("Device address: ", connected_device.get_address())
		print("Device name: ", connected_device.get_name())
		print("Is connected: ", connected_device.is_connected())
		print("Calling discover_services()...")
		connected_device.discover_services()
	else:
		print("No connected device available for service discovery")

func read_characteristic_example(service_uuid: String, char_uuid: String):
	if connected_device:
		print("\n=== Reading characteristic ===")
		print("  Service: ", service_uuid)
		print("  Characteristic: ", char_uuid)
		connected_device.read_characteristic(service_uuid, char_uuid)

func write_characteristic_example(service_uuid: String, char_uuid: String, data: PackedByteArray, with_response: bool = true):
	if connected_device:
		print("\n=== Writing characteristic ===")
		print("  Service: ", service_uuid)
		print("  Characteristic: ", char_uuid)
		print("  Data length: ", data.size())
		connected_device.write_characteristic(service_uuid, char_uuid, data, with_response)

func subscribe_characteristic_example(service_uuid: String, char_uuid: String):
	if connected_device:
		print("\n=== Subscribing to characteristic ===")
		print("  Service: ", service_uuid)
		print("  Characteristic: ", char_uuid)
		connected_device.subscribe_characteristic(service_uuid, char_uuid)

func unsubscribe_characteristic_example(service_uuid: String, char_uuid: String):
	if connected_device:
		print("\n=== Unsubscribing from characteristic ===")
		print("  Service: ", service_uuid)
		print("  Characteristic: ", char_uuid)
		connected_device.unsubscribe_characteristic(service_uuid, char_uuid)
# ===== Signal callbacks =====

func _on_adapter_initialized(success: bool, error: String):
	if success:
		print("Bluetooth adapter initialized successfully")
		adapter_ready = true
		start_scan_button.disabled = false
	else:
		print("Failed to initialize Bluetooth adapter: ", error)

func _on_scan_started():
	print("Scan started")
	scanning = true

func _on_scan_stopped():
	print("Scan stopped")
	scanning = false
	start_scan_button.disabled = false
	# Fetch all discovered devices
	var devices = bluetooth_manager.get_discovered_devices()
	print("\nTotal devices discovered: ", devices.size())

func _on_device_discovered(device_info: Dictionary):
	print("\nDevice discovered:")
	print("  Name: ", device_info.get("name", "Unknown"))
	print("  Address: ", device_info.get("address", ""))
	print("  RSSI: ", device_info.get("rssi", 0), " dBm")

	var address: String = device_info.get("address", "")
	if address == "":
		return
	var raw_name = device_info.get("name")
	var device_name: String = str(raw_name) if raw_name != null else "Unknown"
	var label := "%s (%s)" % [device_name, address]
	var raw_rssi = device_info.get("rssi")
	var rssi: int = 0
	if raw_rssi is int:
		rssi = raw_rssi
	elif raw_rssi is float:
		rssi = int(raw_rssi)

	if address_to_index.has(address):
		var idx: int = address_to_index[address]
		device_list.set_item_text(idx, label)
		device_list.set_item_tooltip(idx, "RSSI: %s dBm" % rssi)
	else:
		var idx: int = device_list.get_item_count()
		device_list.add_item(label)
		device_list.set_item_metadata(idx, address)
		device_list.set_item_tooltip(idx, "RSSI: %s dBm" % rssi)
		address_to_index[address] = idx

func _on_device_connected(address: String):
	print("Device connected (manager signal): ", address)

func _on_device_disconnected(address: String):
	print("Device disconnected (manager signal): ", address)
	connected_device = null
	start_scan_button.disabled = false

func _on_device_connected_signal():
	print("Device connected successfully")
	# After connecting, discover services
	print("Calling discover_services()...")
	discover_services()

func _on_device_disconnected_signal():
	print("Device disconnected")
	connected_device = null

func _on_connection_failed(error: String):
	print("Connection failed: ", error)
	connected_device = null

func _on_services_discovered(services: Array):
	print("\n=== Services discovered callback ===")
	print("Received services array, size: ", services.size())
	print("Services data: ", services)
	service_list.clear()
	characteristic_list.clear()
	current_services = services.duplicate(true)
	
	if services.size() == 0:
		print("No services discovered")
		return
		
	print("\nServices discovered:")
	for service in services:
		var service_uuid = service.get("uuid", "")
		print("  Service UUID: ", service_uuid)
		
		var characteristics = service.get("characteristics", [])
		print("    Characteristics count: ", characteristics.size())
		var label := "%s (%d chars)" % [service_uuid, characteristics.size()]
		var idx: int = service_list.get_item_count()
		service_list.add_item(label)
		service_list.set_item_metadata(idx, service)
		service_list.set_item_tooltip(idx, "Characteristics: %d" % characteristics.size())
		for characteristic in characteristics:
			var char_uuid = characteristic.get("uuid", "")
			var properties = characteristic.get("properties", {})
			print("    Characteristic UUID: ", char_uuid)
			print("      Can Read: ", properties.get("read", false))
			print("      Can Write: ", properties.get("write", false))
			print("      Can Write Without Response: ", properties.get("write_without_response", false))
			print("      Can Notify: ", properties.get("notify", false))
			print("      Can Indicate: ", properties.get("indicate", false))
	
	# Look for the fff0 service and process its characteristics
	var fff0_service_found = false
	var fff1_subscribed = false
	var fff2_written = false
	
	for service in services:
		var service_uuid = service.get("uuid", "")
		var characteristics = service.get("characteristics", [])
		
		print("Checking service: ", service_uuid)
		
		# Check whether this is the fff0 service (UUID: 0000fff0-0000-1000-8000-00805f9b34fb)
		if service_uuid == "0000fff0-0000-1000-8000-00805f9b34fb":
			print("\n=== Found fff0 service: ", service_uuid, " ===")
			fff0_service_found = true
			
			for characteristic in characteristics:
				var char_uuid = characteristic.get("uuid", "")
				var properties = characteristic.get("properties", {})
				print("  Checking characteristic: ", char_uuid)
				
				# Subscribe to fff1 notifications
				if char_uuid == "0000fff1-0000-1000-8000-00805f9b34fb":
					print("  Found fff1 characteristic: ", char_uuid)
					if properties.get("notify", false):
						print("  Subscribing to fff1 notifications...")
						subscribe_characteristic_example(service_uuid, char_uuid)
						fff1_subscribed = true
					else:
						print("  Warning: fff1 does not support notifications")
				
				# Write data to the fff2 characteristic
				elif char_uuid == "0000fff2-0000-1000-8000-00805f9b34fb":
					print("  Found fff2 characteristic: ", char_uuid)
					if properties.get("write", false) or properties.get("write_without_response", false):
						# Write the string "hello gdble"
						var test_string = "hello gdble"
						var test_data = test_string.to_utf8_buffer()
						print("  Writing string '", test_string, "' to fff2 characteristic")
						write_characteristic_example(service_uuid, char_uuid, test_data, false)
						fff2_written = true
					else:
						print("  Warning: fff2 does not support write operations")
			
			# Exit the loop after handling the fff0 service
			break
	
	# Print an operation summary
	if fff0_service_found:
		print("\n=== fff0 Service Operations Summary ===")
		print("  fff1 notification subscribed: ", fff1_subscribed)
		print("  fff2 data written: ", fff2_written)
	else:
		print("\nWarning: fff0 service not found")


func _on_characteristic_read(char_uuid: String, data: PackedByteArray):
	print("\nCharacteristic read:")
	print("  UUID: ", char_uuid)
	print("  Data length: ", data.size())
	print("  Data (hex): ", data.hex_encode())

func _on_characteristic_written(char_uuid: String):
	print("\nCharacteristic written successfully:")
	print("  UUID: ", char_uuid)

func _on_characteristic_notified(char_uuid: String, data: PackedByteArray):
	print("\n=== Characteristic Notification Received ===")
	print("  UUID: ", char_uuid)
	print("  Data length: ", data.size())
	print("  Data (hex): ", data.hex_encode())
	
	# Attempt to decode data as a string
	var data_string = data.get_string_from_utf8()
	if data_string != "":
		print("  Data (string): ", data_string)
	
	# Highlight notifications coming from fff1
	if char_uuid.to_lower() == "0000fff1-0000-1000-8000-00805f9b34fb":
		print("  >>> This is from fff1 characteristic! <<<")

func _on_operation_failed(operation: String, error: String):
	print("\nOperation failed:")
	print("  Operation: ", operation)
	print("  Error: ", error)

func _on_error_occurred(error_message: String):
	print("\nError occurred: ", error_message)

func _on_item_selected(index: int):
	var address = device_list.get_item_metadata(index)
	if address == null:
		print("No address metadata for selected item")
		return
	if connected_device and connected_device.get_address() == String(address):
		print("Already connected to selected device")
		return
	if scanning:
		bluetooth_manager.stop_scan()
	print("Connecting to selected device from list")
	connect_to_device(String(address))

func _on_service_selected(index: int):
	var service = service_list.get_item_metadata(index)
	if service == null:
		print("No service metadata for selected item")
		return
	var service_uuid: String = service.get("uuid", "")
	var characteristics: Array = service.get("characteristics", [])
	print("\n=== Service selected ===")
	print("Service UUID: ", service_uuid)
	print("Characteristic count: ", characteristics.size())
	characteristic_list.clear()
	for characteristic in characteristics:
		var char_uuid = characteristic.get("uuid", "")
		var properties = characteristic.get("properties", {})
		print("  Characteristic: ", char_uuid)
		print("    Properties: read=", properties.get("read", false), ", write=", properties.get("write", false), ", write_no_resp=", properties.get("write_without_response", false), ", notify=", properties.get("notify", false), ", indicate=", properties.get("indicate", false))
		var modes := []
		if properties.get("read", false):
			modes.append("read")
		if properties.get("notify", false):
			modes.append("notify")
		if modes.size() == 0:
			continue
		var label := "%s (%s)" % [char_uuid, ",".join(modes)]
		var cidx: int = characteristic_list.get_item_count()
		characteristic_list.add_item(label)
		characteristic_list.set_item_metadata(cidx, {
			"service_uuid": service_uuid,
			"char_uuid": char_uuid,
			"can_read": properties.get("read", false),
			"can_notify": properties.get("notify", false),
		})
		characteristic_list.set_item_tooltip(cidx, "Modes: %s" % ",".join(modes))

func _on_characteristic_selected(index: int):
	var meta = characteristic_list.get_item_metadata(index)
	if meta == null:
		print("No characteristic metadata for selected item")
		return
	if connected_device == null:
		print("No connected device to read characteristic")
		return
	var service_uuid: String = meta.get("service_uuid", "")
	var char_uuid: String = meta.get("char_uuid", "")
	print("Reading/subscribing characteristic from list selection: ", service_uuid, " / ", char_uuid)
	var can_read: bool = meta.get("can_read", false)
	var can_notify: bool = meta.get("can_notify", false)
	if can_read:
		connected_device.read_characteristic(service_uuid, char_uuid)
	if can_notify:
		connected_device.subscribe_characteristic(service_uuid, char_uuid)
	# Unsubscribe previous notify selection when switching
	if connected_device:
		for i in range(characteristic_list.get_item_count()):
			if i == index:
				continue
			var prev_meta = characteristic_list.get_item_metadata(i)
			if prev_meta and prev_meta.get("can_notify", false):
				var prev_service = prev_meta.get("service_uuid", "")
				var prev_char = prev_meta.get("char_uuid", "")
				if prev_service != "" and prev_char != "":
					connected_device.unsubscribe_characteristic(prev_service, prev_char)

func _exit_tree():
	# Clean up resources
	if connected_device:
		connected_device.disconnect()
	if bluetooth_manager:
		bluetooth_manager.stop_scan()
