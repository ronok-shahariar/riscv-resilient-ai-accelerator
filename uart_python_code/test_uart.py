import serial

ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=0.1)
print("Listening for raw bytes... Press board reset.")
while True:
  data = ser.read(100)
  if data:
    print(f"Received raw: {data}")
