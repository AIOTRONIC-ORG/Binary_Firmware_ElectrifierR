import serial
import re
import time
import sys
import qrcode
from PIL import Image
import serial.tools.list_ports

def generate_qr(mac):
    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(mac)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color='black', back_color='white').convert('RGB')
    qr_img.save('mac_qr.png')
    print('QR code saved as mac_qr.png')

def wait_for_device(port):
    print(f"Waiting for device to reconnect on {port}...")
    while True:
        try:
            s = serial.Serial(port, 115200, timeout=1)
            s.close()
            print(f"Device reconnected on {port}")
            return
        except serial.SerialException:
            time.sleep(1)

def monitor_serial(port):
    mac_pattern = re.compile(r'^([0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2})$')
    
    print("Waiting for device to disconnect...")
    while True:
        try:
            s = serial.Serial(port, 115200, timeout=1)
            s.close()
            time.sleep(1)
        except serial.SerialException:
            print("Device disconnected. Waiting for reconnection...")
            break

    wait_for_device(port)
    
    try:
        s = serial.Serial(port, 115200, timeout=1)
        print('Monitoring for MAC address...')
        start_time = time.time()
        mac_found = False
        
        while time.time() - start_time < 60 and not mac_found:
            try:
                line = s.readline().decode('utf-8', errors='replace').strip()
                print(f"Received: {line}")  
                
                if line:  
                    match = mac_pattern.search(line)
                    if match:
                        mac_found = True
                        mac = match.group(1).upper()
                        
                        with open('mac_address.txt', 'w') as f:
                            f.write(mac)
                        print(f'MAC address found and saved: {mac}')
                        
                        generate_qr(mac)
                        break
            except UnicodeDecodeError:
                print("Received non-UTF8 data, skipping...")
        
        if not mac_found:
            print('No MAC address found within 60 seconds.')
        
        s.close()
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        port = sys.argv[1]
        monitor_serial(port)
    else:
        print("Please provide a COM port as an argument.")
