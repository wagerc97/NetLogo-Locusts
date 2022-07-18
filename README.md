# Model of Spatial Dynamics of Desert Locust Populations
**Quicklinks:**  
- [Link](http://ccl.northwestern.edu/netlogo/models/community/locusts_rain) to NetLogo User Community Models to run the model online yourself
- [Presentation slides](./slides.pdf) to view


## WHAT IS IT?

The locusts species _Schistocerca gregaria_ has two lifestyle phases to deal with environmental changes that exhibit their own behavior. They live on grass patches in the desert. High density populations will trigger a phase change and "gregarious" locusts appear. They form swarms and search the desert for food. When they find a grass patch they will land and start to eat. After distributing over the patch the phase change may trigger again as the density reduces. Then "solitary" locusts will roam the area on their own looking for food.   

**This is what the NetLogo interface looks like:**
![model-interface](https://user-images.githubusercontent.com/75813930/178964935-748d6c29-81eb-499f-9ea8-d07f601078ca.png)

## HOW IT WORKS!

### Environment 
When the model is set up, it spawns grass patches in random places that may overlap. Some patches remain desert and never grow any grass. Grass patches hold certain amount of food. We altered this parameter as well as the number and the size of patches to answer our research questions. 
After a certain number of ticks, the rainy season starts for 100 ticks. During this time the grass grows back on its patches and the locusts find food again. 

### Turtles
Upon setup 50 (default) solitary locusts are spawned in random places. Each one has energy, a memory of encounters and an age. 

### Behavior
Essentially, turtles wander, look for food and reproduce when they doubled their energy. When they doubled their initial energy, they spawn a random number of offspring and die. 

The solitary locusts (phase 1) will avoid contact with each other and turn around when encountering other locusts. However, their priority is finding food such they can reproduce. Otherwise they randomly walk around. 

Their interaction with the environment will trigger a phase change. At some point locusts will have finished eating up a whole grass patch. Then they are stuck together in the desert and have a lot of contact with each other. Their memory of encounters will increase and when it hits a certain threshold individuals turn into a gregarious locust (change of breed).

Now the gregarious locusts (phase 2) have very different behavior. Their top priority remains finding food to reproduce. But if there is no food around them, they will flock and form a swarm with their neighboring gregarious locusts. (Here we copied and adapted code from “Flocking” in the NetLogo Models Library that uses a lot of trigonometry.) 

The flock moves faster and more energy efficient than single locusts. The goal of the flock is to find food and they can sense grass patches over long distances. Flocking locusts will stay together, and some swarms also merge to become a larger swarm if they are close together. 

Once a flock finds a grass patch and lands, the gregarious locusts will start to look for food on their own. This behavior may reduce their encounter memory and they may turn back into solitary phase. 

### Balance

- We introduced individual age such that locusts cannot carry on with this behavior forever
- Simulation runs stable over 10,000 ticks, but gets very slow
- Periodic behavior changes visibly 
- Environment regenerates periodically 
- It took some time to find the right parameters and dynamics to balance the system. But we needed a reference model for our research questions. 



## HOW TO USE IT

The most interesting parameter to experiment with is `rain-interval`. Swarms will endure the dry periods better than solitary locusts. 

(how to use the model, including a description of each of the items in the Interface tab)
... oof there are a lot of parameters, but their names speak for themselves. However, I recommend only changing the upper parameters and not the once below the plot. 



## THINGS TO NOTICE

Enjoy observing the locusts living their life and periodically changing their behaviour through interaction with their environment.  
The code for the `eat` procedure was designed with great care for ecological balance. The amount of food and thes the energy taken up by individuals have a 1:1 relation. 



## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)
Try changing the size of the space.
Alter parameters via sliders (Only the upper interface is recommended to experiment with)


## EXTENDING THE MODEL

One possibility of extension would be to implement a switch to generate a space with evenly distributed grass instead of randomly placed patches.

How to implement the `break` in the `foreach` loop of the `eat` procedure?? Please contact me if you find out haha


## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)
- foreach loop in eat procedure
- trigonometry in swarm movement 
- modulo to define the seasonal intervals



## RELATED MODELS

We copied and adapted the flocking behavior code from the NetLogo Models Library/Biology/Flocking.
We used some principles form the Wolf-and-Sheep Model which is also part of the NetLogo Models Library.



## CREDITS AND REFERENCES

Authors: Jeremy Cook and Clemens Wager
Last revisited on 19.06.2022    

### Background knowledge 

Collett et al. 1998 PNAS https://www.ncbi.nlm.nih.gov/pmc/articles/PMC23706/  
Cressman 2016 https://www.researchgate.net/publication/301261147_Desert_Locust  
Guo et al. 2020 Nature https://www.nature.com/articles/s41586-020-2610-4  
Simpson et al. 2001 PNAS https://www.ncbi.nlm.nih.gov/pmc/articles/PMC31149/  
UN-FAO https://www.fao.org/locusts-cca/bioecology/what-are-locusts/en/#:~:text=In%20solitary%20phase%20(low%20numbers,which%20behave%20as%20an%20entity  
Wired https://www.wired.com/story/the-terrifying-science-behind-the-locust-plagues-of-africa/  
