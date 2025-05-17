import asyncio
import websockets
import json
import argparse
import random
import time

async def send_sensor_data(token, base_url="localhost:8000"):
    """
    Send simulated sensor data to the WebSocket endpoint.
    
    Args:
        token (str): The JWT token
        base_url (str): The base URL of the API
    """
    uri = f"ws://{base_url}/api/v1/sensor/ws?token={token}"
    
    try:
        async with websockets.connect(uri) as websocket:
            print(f"Connected to {uri}")
            
            # Send data every 3 seconds
            while True:
                # Generate random sensor data
                data = {
                    "temperature": round(random.uniform(20.0, 30.0), 1),
                    "humidity": round(random.uniform(40.0, 80.0), 1),
                    "obstacle": random.choice([True, False])
                }
                
                # Send the data
                await websocket.send(json.dumps(data))
                print(f"Sent: {data}")
                
                # Receive the response
                response = await websocket.recv()
                print(f"Received: {response}")
                
                # Wait for 3 seconds
                await asyncio.sleep(3)
    except websockets.exceptions.ConnectionClosed as e:
        print(f"Connection closed: {e}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test WebSocket connection")
    parser.add_argument("--token", "-t", required=True, help="JWT token")
    parser.add_argument("--base-url", "-b", default="localhost:8000", help="Base URL of the API")
    
    args = parser.parse_args()
    
    try:
        asyncio.run(send_sensor_data(args.token, args.base_url))
    except KeyboardInterrupt:
        print("Stopped by user")
