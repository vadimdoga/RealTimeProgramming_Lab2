#!/usr/bin/env python3
import paho.mqtt.client as mqtt

# This is the Subscriber

def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))
    client.subscribe("test")


def on_message(client, userdata, msg):
    topic = msg.topic
    payload = msg.payload
    qos = msg.qos
    retain = msg.retain

    print(topic)
    print(payload)
    print(qos)
    print(retain)
    # if decoded_msg:
    #     print("Received message {}".format(decoded_msg))


client = mqtt.Client("Server")
client.connect('localhost', 1883)


client.on_connect = on_connect
client.on_message = on_message

client.loop_forever()

# import socket
# import sys

# # Create a TCP/IP socket
# sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# server_address = ('localhost', 10000)
# print("Starting up on address {}".format(server_address))
# sock.bind(server_address)

# sock.listen(1)

# while True:
#     # Wait for a connection
#     print("waiting for connection")
#     connection, client_address = sock.accept()
#     try:
#         print("connection from {}", client_address)

#         # Receive the data in small chunks and retransmit it
#         while True:
#             data = connection.recv(16)
#             print(data)
#             if data:
#                 print >>sys.stderr, 'sending data back to the client'

#             else:
#                 print >>sys.stderr, 'no more data from', client_address
#                 break

#     finally:
#             # Clean up the connection
#         connection.close()
