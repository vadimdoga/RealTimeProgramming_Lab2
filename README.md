# Laboratory Work on Real Time Programming

## Tasks
```
You will have to make a publisher-subscriber system, with a message broker and some subscribers, each performing different duties. This lab requires a tiny bit of refactoring of the first lab + some additional work. Regarding the subscribers, you will need three or more. One of them will have to do a streaming approximate join of information from 3 different API routes, another will do forecast printing or showing on a dashboard. Finally, you will be required to create a subscriber/adapter for MQTT protocol.

Step 1 - Use the first lab for publishers, with some minor tweaking.

Step 2 - Same as last time, docker pull alexburlacu/rtp-server:lab2 and launch it (note the :lab2 part, don't forget it), 
then forward the port 4000. But now you have 2 more routes beside the /iot, these are /sensors and /legacy_sensors. 
Oh, and the measurements are sharded, that is not all 10 duplicated sensors are on the same route. 
You will have to join them, but more on that later. Also, messages on the routes have different formats. 
Two of these output JSONs, one XMLs.

Stage 2.1 - Note that due to a sharded representation, your worker actors can no longer compute the weather forecast. 
But they can still parse the data and compute the mean between duplicate sensors. And of course crash in case of the PANIC message. 
Just downscale a bit the number of workers, for you will, as an option, run 3 instances of the same program, 
with only different parsers and reading from different routes. Even better, make them be publishers, for an additional point.

Step 3 - Design and implement your own Message Broker. Usage of existing solutions, like RabbitMQ or something else, is prohibited. 
As a minimum, it must support multiple topics, the possibility to unsubscribe and subscribe dynamically. 
So no hardcoded publishers and subscribers. Also, keep in mind, a Message Broker is a separate entity that requires some transport protocol to communicate with. I suggest UDP. But if you want to use TCP, that's fine.

Stage 4 - Now you need Subscribers. For this laboratory, you will need at least 3. One is already 3/4 done: pretty print the measurements, or if you have it, run the dashboard from the previous lab. The next one is 1/4 done: the forecast generator. 
You should by now have the rule engine for making forecasts, and the aggregator. 
But now you will also have to do a streaming join, by timestamp. Once the join is done, you can either publish back on a separate topic for another subscriber to compute the windowed forecast or do it on the same subscriber. 
Although, the former approach is recommended. Finally, the 3rd mandatory subscriber will have to be an adapter to MQTT protocol. 
That is, the data that you read will be then passed on in compliance with the MQTT protocol. 
Here, republishing joined data could be useful, so as to transmit only readings from a single "virtual" sensor.

The basic requirements are:
- Process events as soon as they come
- Have 3 groups of workers parsing and averaging the measurements and 3 supervisors, or one, whatever, depends on how you will tackle the publishers part
- Dynamically change the number of actors (up and down) depending on the load
- In case of a special `panic` message, kill the worker actor and then restart it 
- Make a message broker that supports multiple topics, subscribing and unsubscribing, no hardcoding
- Develop at least 3 subscribers that will (1) print the results, (2) compute forecast, and (3) be an MQTT adapter. 
- The code must be published on Github, otherwise, the lab will not be accepted + please do put it into a container, so I or anyone else can run it locally without much hassle
- Remember the single responsibility principle, in this case - one actor/group of actors per task -> use a different actor for collecting data, creating the forecast, aggregating results, pretty-printing  to console, anything else

```

## Output
1. Pretty Printing\
![frc](https://user-images.githubusercontent.com/43139007/81674003-33c68280-9455-11ea-8ef5-614ee8a0c710.png)

2. Logger info\
![logger](https://user-images.githubusercontent.com/43139007/81674002-332dec00-9455-11ea-8cf4-ac8e8417d117.png)

3. MQTT Subscriber\
![mqtt](https://user-images.githubusercontent.com/43139007/81673998-31fcbf00-9455-11ea-92e7-ab997e6898e7.png)

## Start the project
```
docker pull alexburlacu/rtp-server:lab2
docker run -p 4000:4000 rtp-server_img
mix run
```
