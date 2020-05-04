# RealTimeProgramming_Lab2

## Tasks
```
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
