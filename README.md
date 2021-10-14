# tail2speech
arduino and processing sources for a dog-tail sensor. The sensor is -just- a wireless motion sensor using an accelerometer and bluetooth. Raw data of the sensor is relayed over bluetooth-serial to a processing sketch (doing signal processing in processing.org). FFT on X-axis motion is used to determine the 'wagging' of the tail, value on the Y-axis is used to determine whether the tail is up or down.  

The setup consists of an ESP32 board with 
  * small 150 mAh lithium battery
  * GY-85 accelerometer/gyro (IMU)
  * bluetooth connection

This board is wrapped around a dog's tail using small velcro straps. The setup has only been tested with large (adult golden retriever) dogs who don't notice the small sensor, the velcro straps do not have to be very tight as the dog's fur also keeps the sensor in place

In order to produce sound, (much like the dog-with-collar from the movie 'up!') a neck-band is strapped on containing a small JBL-Go bluetooth speaker. The neckband used during the show is part of a hood which is bought in a vetinary shop (normally used for dogs with damaged ears or a head wound). The weight again is small (with respect to a large golden retriever)

# disclaimer
Of course this project does not (cannot) claim to be fit for any purpose. When you play with animals (and electronics) you have to be really aware of what you are doing. Think about the risk of your dog swallowing electronics, biting a battery or shaking off and throwing an expensive speaker through the room. -IF- you are building such a thing and using it with a live animal, make sure never to leave your pet unattended. Dogs will bite and eat anything so be really really really careful.  

The electronics are (deliberately) wireless. Sticking wires to an (active) dog is both dangerous from a mechanical point of view (entanglement) and electrical (electrocution). Whatever you do, don't connect wires to things wrapped to your dog.. 
