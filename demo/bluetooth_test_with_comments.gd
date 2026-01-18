extends Node

# ============================================================================
# Bluetooth plugin test script - detailed annotations
# ============================================================================
# 
# This script demonstrates how to use the GDBLE plugin for Bluetooth tasks:
# 1. Initialize the Bluetooth adapter
# 2. Scan nearby BLE devices
# 3. Connect to the target device (Fantety11)
# 4. Discover services and characteristics
# 5. Subscribe to fff1 notifications (receive data)
# 6. Write data to the fff2 characteristic (send data)
#
# ============================================================================

var bluetooth_manager: BluetoothManager
var connected_device: BleDevice = null

# UUID for the fff0 service
const FFF0_SERVICE = "0000fff0-0000-1000-8000-00805f9b34fb"
# UUID for the fff1 characteristic (notifications)
const FFF1_CHARACTERISTIC = "0000fff1-0000-1000-8000-00805f9b34fb"
# UUID for the fff2 characteristic (writes)
const FFF2_CHARACTERISTIC = "0000fff2-0000-1000-8000-00805f9b34fb"

func _ready():
	print("=== GDBLE Bluetooth Plugin Test ===")
	print("This script will:")
	print("  1. Initialize Bluetooth adapter")
	print("  2. Scan for devices")
	print("  3. Connect to 'Fantety11' device")
	print("  4. Subscribe to fff1 notifications")
	print("  5. Write data to fff2 characteristic")
	print()
	
	# Step 1: Create the BluetoothManager instance
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)
	
	# Step 2: Connect all required signals
	setup_signals()
	
	# Step 3: Initialize the Bluetooth adapter
	print("Initializing Bluetooth adapter...")
	# Turn off debug chatter (set to true during development if needed)
	bluetooth_manager.set_debug_mode(false)
	bluetooth_manager.initialize()

func setup_signals():
	"""Connect all Bluetooth manager and device signals"""
	# BluetoothManager signals
	bluetooth_manager.adapter_initialized.connect(_on_adapter_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_discovered)
	bluetooth_manager.device_connected.connect(_on_device_connected)
	bluetooth_manager.device_disconnected.connect(_on_device_disconnected)
	bluetooth_manager.scan_started.connect(_on_scan_started)
	bluetooth_manager.scan_stopped.connect(_on_scan_stopped)
	bluetooth_manager.error_occurred.connect(_on_error_occurred)

func start_scanning():
	"""Start scanning nearby BLE devices"""
	print("\n=== Starting BLE Device Scan ===")
	# Scan for 10 seconds
	bluetooth_manager.start_scan(10.0)

func connect_to_device(address: String):
	"""Connect to the BLE device at the given address"""
	print("\n=== Connecting to Device ===")
	print("  Address: ", address)
	
	# Create the device instance through BluetoothManager
	var device = bluetooth_manager.connect_device(address)
	if device:
		print("  Device instance created")
		connected_device = device
		
		# Wire up all device signals
		print("  Setting up device signals...")
		device.connected.connect(_on_device_connected_signal)
		device.disconnected.connect(_on_device_disconnected_signal)
		device.connection_failed.connect(_on_connection_failed)
		device.services_discovered.connect(_on_services_discovered)
		device.characteristic_read.connect(_on_characteristic_read)
		device.characteristic_written.connect(_on_characteristic_written)
		device.characteristic_notified.connect(_on_characteristic_notified)
		device.operation_failed.connect(_on_operation_failed)
		
		# Begin the asynchronous connection
		print("  Initiating connection...")
		device.connect_async()
	else:
		print("  ERROR: Failed to create device instance")

func discover_services():
	"""Discover services and characteristics on the connected device"""
	if connected_device:
		print("\n=== Discovering Services ===")
		print("  Device: ", connected_device.get_name())
		print("  Address: ", connected_device.get_address())
		print("  Connected: ", connected_device.is_connected())
		connected_device.discover_services()
	else:
		print("ERROR: No connected device")

# ============================================================================
# Signal callbacks - BluetoothManager
# ============================================================================

func _on_adapter_initialized(success: bool, error: String):
	"""Bluetooth adapter initialization finished"""
	if success:
		print("✓ Bluetooth adapter initialized")
		# Start scanning automatically after initialization succeeds
		start_scanning()
	else:
		print("✗ Bluetooth initialization failed: ", error)

func _on_scan_started():
	"""Scan started"""
	print("✓ Scan started")

func _on_scan_stopped():
	"""Scan stopped; process discovered devices"""
	print("✓ Scan stopped")
	
	# Fetch all discovered devices
	var devices = bluetooth_manager.get_discovered_devices()
	print("\n=== Scan Results ===")
	print("  Total devices found: ", devices.size())
	
	# Look for the target device "Fantety11"
	var target_address = ""
	for device in devices:
		var name = device.get("name", "")
		if name == "Fantety11":
			target_address = device.get("address", "")
			print("  ✓ Found target device: Fantety11")
			break
	
	# Connect to the target device
	if target_address != "":
		connect_to_device(target_address)
	elif devices.size() > 0 and connected_device == null:
		# If the target is not found, connect to the first device (for testing)
		var first_device = devices[0]
		var address = first_device.get("address", "")
		var name = first_device.get("name", "Unknown")
		print("  Target device not found, connecting to: ", name)
		connect_to_device(address)
	else:
		print("  ✗ No devices available to connect")

func _on_device_discovered(device_info: Dictionary):
	"""Callback when a new device is discovered"""
	var name = device_info.get("name", "Unknown")
	var address = device_info.get("address", "")
	var rssi = device_info.get("rssi", 0)
	print("  Device: ", name, " (", address, ") RSSI: ", rssi, " dBm")

func _on_device_connected(address: String):
	"""Device connected (manager signal)"""
	print("✓ Device connected (manager): ", address)

func _on_device_disconnected(address: String):
	"""Device disconnected (manager signal)"""
	print("✗ Device disconnected (manager): ", address)
	connected_device = null

func _on_error_occurred(error_message: String):
	"""Error occurred"""
	print("✗ Error: ", error_message)

# ============================================================================
# Signal callbacks - BleDevice
# ============================================================================

func _on_device_connected_signal():
	"""Device connected (device signal)"""
	print("✓ Device connected successfully")
	# Discover services immediately after connecting
	discover_services()

func _on_device_disconnected_signal():
	"""Device disconnected (device signal)"""
	print("✗ Device disconnected")
	connected_device = null

func _on_connection_failed(error: String):
	"""Connection failed"""
	print("✗ Connection failed: ", error)
	connected_device = null


func _on_services_discovered(services: Array):
	"""Service discovery finished; process the fff0 service"""
	print("\n=== Services Discovered ===")
	print("  Total services: ", services.size())
	
	if services.size() == 0:
		print("  ✗ No services found")
		return
	
	# Find and handle the fff0 service
	var fff0_found = false
	var fff1_subscribed = false
	var fff2_written = false
	
	for service in services:
		var service_uuid = service.get("uuid", "")
		
		# Check whether this is the fff0 service
		if service_uuid == FFF0_SERVICE:
			print("\n=== Processing fff0 Service ===")
			print("  Service UUID: ", service_uuid)
			fff0_found = true
			
			var characteristics = service.get("characteristics", [])
			print("  Characteristics: ", characteristics.size())
			
			# Iterate characteristics
			for characteristic in characteristics:
				var char_uuid = characteristic.get("uuid", "")
				var properties = characteristic.get("properties", {})
				
				# Handle the fff1 characteristic (subscribe to notifications)
				if char_uuid == FFF1_CHARACTERISTIC:
					print("\n  [fff1] Notification Characteristic")
					print("    UUID: ", char_uuid)
					print("    Can Notify: ", properties.get("notify", false))
					
					if properties.get("notify", false):
						print("    >>> Subscribing to notifications...")
						subscribe_to_fff1()
						fff1_subscribed = true
					else:
						print("    ✗ Warning: Notifications not supported")
				
				# Handle the fff2 characteristic (write data)
				elif char_uuid == FFF2_CHARACTERISTIC:
					print("\n  [fff2] Write Characteristic")
					print("    UUID: ", char_uuid)
					print("    Can Write: ", properties.get("write", false))
					print("    Can Write Without Response: ", properties.get("write_without_response", false))
					
					if properties.get("write", false) or properties.get("write_without_response", false):
						print("    >>> Writing test data...")
						write_to_fff2("hello gdble")
						fff2_written = true
					else:
						print("    ✗ Warning: Write not supported")
			
			# Stop after finding the fff0 service
			break
	
	# Output operation summary
	print("\n=== Operation Summary ===")
	if fff0_found:
		print("  ✓ fff0 service found")
		print("  fff1 subscribed: ", "✓" if fff1_subscribed else "✗")
		print("  fff2 written: ", "✓" if fff2_written else "✗")
		
		if fff1_subscribed:
			print("\n>>> Waiting for notifications from fff1...")
			print(">>> Any data received will be displayed below")
	else:
		print("  ✗ fff0 service not found")

func subscribe_to_fff1():
	"""Subscribe to notifications on the fff1 characteristic"""
	if connected_device:
		connected_device.subscribe_characteristic(FFF0_SERVICE, FFF1_CHARACTERISTIC)

func write_to_fff2(text: String):
	"""Write text data to the fff2 characteristic"""
	if connected_device:
		var data = text.to_utf8_buffer()
		# Use write-without-response (faster)
		connected_device.write_characteristic(FFF0_SERVICE, FFF2_CHARACTERISTIC, data, false)

func _on_characteristic_read(char_uuid: String, data: PackedByteArray):
	"""Characteristic read completed"""
	print("\n=== Characteristic Read ===")
	print("  UUID: ", char_uuid)
	print("  Length: ", data.size(), " bytes")
	print("  Hex: ", data.hex_encode())
	
	var text = data.get_string_from_utf8()
	if text != "":
		print("  Text: ", text)

func _on_characteristic_written(char_uuid: String):
	"""Characteristic write completed"""
	print("\n=== Characteristic Written ===")
	print("  UUID: ", char_uuid)
	
	# Highlight writes to fff2
	if char_uuid.to_lower() == FFF2_CHARACTERISTIC:
		print("  ✓ Data successfully written to fff2")

func _on_characteristic_notified(char_uuid: String, data: PackedByteArray):
	"""Received characteristic notification (primary data path)"""
	print("=== NOTIFICATION RECEIVED ===")
	print("  UUID: ", char_uuid)
	print("  Length: ", data.size(), " bytes")
	print("  Hex: ", data.hex_encode())
	
	# Try to parse as text
	var text = data.get_string_from_utf8()
	if text != "":
		print("  Text: '", text, "'")
	
	# Highlight notifications from fff1
	if char_uuid.to_lower() == FFF1_CHARACTERISTIC:
		print("\n  >>> This notification is from fff1 characteristic! <<<")
		print("  >>> Your device sent this data <<<")

func _on_operation_failed(operation: String, error: String):
	"""Operation failed"""
	print("\n✗ Operation Failed")
	print("  Operation: ", operation)
	print("  Error: ", error)

# ============================================================================
# Cleanup
# ============================================================================

func _exit_tree():
	"""Clean up resources when the node is destroyed"""
	print("\n=== Cleaning Up ===")
	
	if connected_device:
		print("  Disconnecting device...")
		connected_device.disconnect()
	
	if bluetooth_manager:
		print("  Stopping scan...")
		bluetooth_manager.stop_scan()
	
	print("  Cleanup complete")
