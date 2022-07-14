;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; locusts.nlogo                            ;;
;; Authors: Jeremy Cook and Clemens Wager   ;;
;; Last revisited on 19.06.2022             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define Variables and attributes ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

breed [ locusts-solitary a-locust-solitary ]
breed [ locusts-gregarious a-locust-gregarious ]

turtles-own [
  energy
  encounter-score    ;; memory of contact with peers
  age
]
locusts-gregarious-own [
  flockmates         ;; agentset of nearby turtles
  nearest-neighbor   ;; closest one of our flockmates
  food-patch         ;; grass patches nearby
]
patches-own [
  grass-amount       ;; amount of grass = food for locusts
  grass-amount-high  ;; maximum grass-amount of non desert patches
  desert?            ;; Boolean
]

;;;;;;;;;;;;;;;;;;;;;;
;; Setup procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape turtles "bug"
  ask patches [ set desert? True ]
  ask patches [ recolor-grass ]
  setup-grass-patches
  setup-locusts
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

to go  ;; forever button
  wander
  eat
  ask turtles [ aging ]
  ask patches [ recolor-grass ]
  phase-check
  ask turtles [ reproduce ]
  if not any? turtles [ stop ] ;; stopping criterion
  let-it-rain
  tick
end


;;;;;;;;;;;
;; SETUP ;;
;;;;;;;;;;;

to setup-locusts
  create-locusts-solitary number-of-locusts [
    set size 1
    set color yellow
    setxy random-xcor random-ycor
    set energy 100
    set encounter-score 0
    set age 0
  ]
end


to setup-grass-patches
  ;; Place grass patches in random places
  ask patches [ set grass-amount 0 ] ;; base level of grass-amount
  repeat number-of-patches [
    ask one-of patches [
      ask patches with [ distance myself < size-of-patch ] [
        setup-grass
      ]
    ]
    ask patches [ set grass-amount-high grass-amount ] ;; store the highest grass-amount in each patch
  ]
end

to setup-grass
  ;; Let the grass grow
  set grass-amount grass-amount + max-grass-amount ;; grass-amount overlaps
  set desert? False
  recolor-grass
end


to recolor-grass
  ;; update grass color according to grass-amount
  set pcolor scale-color green grass-amount 0 (max-grass-amount * 5)  ;; color varies on scale
  if grass-amount < 0.01 [ set pcolor brown ]
end

to let-it-rain
  ;; check if it is time for rain
  if rainy-season
    [ ask patches [ regrow-grass ] ] ;; for 100 ticks [ regrow-grass ] with defined regrowth-rate
end

to-report rainy-season
  ;; count the ticks and let it rain
  let rain-status False
  if ticks mod rain-interval < 100 and ticks > 100 [ ;; triggers if rain-interval fits into amount of ticks with residual=0 and always start with dry-season
     set rain-status True
  ]
  report rain-status
end

to regrow-grass ;; patches procedure
  ;; regrows grass until as much as at the start and not on designated desert
  ;; called for x ticks (rainy season)
  if not desert? and grass-amount < grass-amount-high
    [ set grass-amount grass-amount + grass-regrowth-rate ]
end

;;;;;;;;;;;;;;
;; MOVEMENT ;;
;;;;;;;;;;;;;;

to wander
  ask locusts-solitary [ wiggle-solitary ]
  ask locusts-gregarious [
    ;; Behavioral focus: search food > flocking (They will flock if there is no grass left)
    ifelse any? neighbors with [grass-amount > 1] ;; return set of neighboring patch with grass
    [ wiggle-gregarious ] ;; eat grass on patch
    [ flock ] ;; lack of  food -> start swarming
  ]
  ask turtles [
    if not can-move? 1 [ rt 180 ]
    go-forward
    exhaust-energy
    update-encounter-score
  ]
end


to go-forward
  ;; go forward
  ifelse [grass-amount] of patch-here > 0.01 ;; not empty grass patch?
  [ forward 0.5 ]
  [ forward 1 ]
end


to wiggle-solitary
  ;; direction of movement SOLITARY
  ;; Behavioral focus: look for food > avoid contact > random walk
  ifelse any? neighbors with [grass-amount > 1]
    ;; head towards grass nearby
    [ set heading towards one-of neighbors with [grass-amount > 1] ]
    [ ifelse any? other locusts-solitary in-radius soli-vision ;; set range when solitaries react to neighbors
        ;; there is a turtle nearby -> walk back
      [ right 180 + random 60 - random 60 ]
        ;; I am alone
      [ right random 60
        left random 60 ]
  ]
end


to wiggle-gregarious
  ;; direction of movement GREGARIOUS
  ;; Behavioral focus: look for food > random walk (They will flock again if there is no grass left)
  ;; there is a turtle nearby -> approach
  ;; Found food -> head there
  set heading towards one-of neighbors with [grass-amount > 1]  ;; head towards a random direction with grass
end


to exhaust-energy
  ;; lose energy upon moving
  set energy energy - movement-cost
  if energy < 1 [ die ]
end


to update-encounter-score
  ;; Check if there are other turtles nearby
  ;;if encounter-score < 45 and encounter-score >= -10 [
  ifelse count other turtles in-radius 2 >= 2
    [
      set encounter-score encounter-score + 1
      if encounter-score > encounter-limit * 1.5 [ set encounter-score encounter-limit * 1.5 ] ;; correct upper limit
    ]
    [
      set encounter-score encounter-score - 0.5
      if encounter-score < -10 [ set encounter-score -10 ] ;; correct lower limit
    ]
end


;;;;;;;;;;;;;;;
;; REPRODUCE ;;
;;;;;;;;;;;;;;;

to reproduce
  ;; call breed specific reproduction functions
  ask locusts-solitary [reproduce-solitary]
  ask locusts-gregarious [reproduce-gregarious]
end


to reproduce-solitary
  ;; Solitary phase
    if energy >= 200 and age > 50 [
      hatch random 5 + random 5 [ ;; downsized to make it run on laptop
        set energy 100
        set encounter-score -10
        set age 0
    ] die ] ;;RIP
end

to reproduce-gregarious
  ;; Solitary phase
    if energy >= 200 and age > 50 [
    ifelse rainy-season
    ;; more offspring during rainy season
    [ hatch 8 + random 6 [ ;; downsized to make it run on laptop
        set energy 100
        set encounter-score encounter-limit * 0.7
        set age 0
    ] ]
    ;; less offspring during dry season
    [ hatch 5 + random 6 [ ;; downsized to make it run on laptop
        set energy 100
        set encounter-score encounter-limit * 0.7
        set age 0
    ] ]
    die ] ;;RIP
end


to aging
  ;; turtles age every tick until they are [max-age] ticks old
  set age age + 1
  if age >= max-age [ die ] ;;RIP
end


;;;;;;;;;;;;
;; EATING ;;
;;;;;;;;;;;;

to eat
  ;; declare empty list
  let tturtles (list 0)
  ;; store turtles-here into list. Each patch has one list.
  ask patches with [ grass-amount >= bite-size and count turtles-here > 0 ][
    set tturtles (list turtles-here) ]
  ask turtles[
    ;; each turtle on the patch takes a bite of grass until none is left
    foreach tturtles [ t ->
      if [grass-amount] of patch-here >= bite-size [ ;; is there still food left
        ask t [ set energy round (energy + bite-size) ] ;; turtles takes a bite
        ask patch-here [ set grass-amount round (grass-amount - bite-size) ] ;; grass is reduced
      ]
      ;[ stop ] ;; break loop if no food left
    ]
  ]
end


;;;;;;;;;;;;;;;;;;
;; PHASE CHANGE ;;
;;;;;;;;;;;;;;;;;;

to phase-check
  ask locusts-solitary [
    ;; Solitary ones are turned into gregorious ones
    if encounter-score >= encounter-limit [
      set breed locusts-gregarious
      set encounter-score encounter-limit ;; default 30
      set color red
    ]
  ]
  ask locusts-gregarious [
    ;; Gregorious ones are turned into solitary ones
    if encounter-score < encounter-limit [
      set breed locusts-solitary
      set encounter-score 0
      set color yellow
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SWARM BEHAVIOR ;;
;;;;;;;;;;;;;;;;;;;;

to flock  ;; locusts-gregarious procedure
  find-flockmates   ;; define set of flockmates [turtles]
  find-food-patch   ;; define set of patches with food
  if any? flockmates
    [ find-nearest-neighbor
      ifelse distance nearest-neighbor < minimum-separation
        [ separate ]
      [ if any? food-patch   ;;patches with [grass-amount > 0.01] in-radius greg-vision
        [ scent-food ]   ;; swarm heads towards grass-patch
          align   ;; head towards average direction of swarm
          cohere   ;; develop swarm, seek nearest neighbor, seek protection of group
  ]
    set energy energy + 0.1 * count other locusts-gregarious in-radius 1 ;; loose less energy on movement
    if energy >= 200 [ set energy 199 ] ;; correct upper energy limit to prevent reproduction without eating
  ]
end

to find-flockmates
  set flockmates other locusts-gregarious in-radius greg-vision
end

to find-nearest-neighbor
  set nearest-neighbor min-one-of flockmates [distance myself]
end

;;; SEPARATE

to separate
  ;; if too close to nearest neighbor -> turn away by given degrees
  turn-away ([heading] of nearest-neighbor) max-separate-turn
end

;;; SCENT FOOD

to scent-food
    turn-towards next-grass-patch max-food-turn
    forward 0.7
end

to find-food-patch
  set food-patch patches with [grass-amount > 0.01] in-radius (greg-vision * 2)
end

to-report next-grass-patch ;; scent-food
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of food-patch  ;; take average over list of patches
  let y-component mean [cos (towards myself + 180)] of food-patch
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; ALIGN

to align
  ;; turn into average direction of swarm
  turn-towards average-flockmate-heading max-align-turn
end

to-report average-flockmate-heading  ;; ALIGN
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; COHERE

to cohere
  ;; "attraction force" , stay close together
  turn-towards average-heading-towards-flockmates max-cohere-turn
end

to-report average-heading-towards-flockmates  ;; COHERE
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates  ;; take average over list of turtles
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

; Swarming behaviour copied and adapted from "Flocking"
; Found in NetLogo Models Library -> Sample Models -> Biology -> Flocking
; Copyright 1998 Uri Wilensky.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; REPORTS ;;
;;;;;;;;;;;;;

to-report report-grass
  ;; return amount of grass for plot
  report sum [ grass-amount ] of patches / 100
end
@#$#@#$#@
GRAPHICS-WINDOW
566
10
1356
568
-1
-1
4.86
1
10
1
1
1
0
1
1
1
-80
80
-56
56
1
1
1
ticks
30.0

BUTTON
0
10
67
43
SETUP
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
80
10
143
43
GO
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
0
79
172
112
number-of-locusts
number-of-locusts
0
100
50.0
5
1
NIL
HORIZONTAL

PLOT
0
154
558
440
Population Report
ticks
Population count
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Population" 1.0 0 -16777216 true "" "plot count turtles"
"Solitary" 1.0 0 -4079321 true "" "plot count locusts-solitary"
"Gregarious" 1.0 0 -2674135 true "" "plot count locusts-gregarious"
"Grass x100" 1.0 0 -14439633 true "" "plot report-grass"

SLIDER
302
531
474
564
movement-cost
movement-cost
0
1
0.7
0.1
1
NIL
HORIZONTAL

TEXTBOX
37
56
187
74
Turtle settings
13
0.0
1

TEXTBOX
318
12
468
30
Environment settings
13
0.0
0

SLIDER
379
37
551
70
grass-regrowth-rate
grass-regrowth-rate
0
1
0.3
0.05
1
NIL
HORIZONTAL

SLIDER
380
115
552
148
max-grass-amount
max-grass-amount
0
20
8.0
1
1
NIL
HORIZONTAL

SLIDER
200
37
372
70
size-of-patch
size-of-patch
0
30
12.0
1
1
NIL
HORIZONTAL

SLIDER
200
76
372
109
number-of-patches
number-of-patches
0
25
10.0
1
1
NIL
HORIZONTAL

SLIDER
0
116
172
149
soli-vision
soli-vision
0
4
2.0
0.5
1
NIL
HORIZONTAL

INPUTBOX
0
465
57
525
max-age
500.0
1
0
Number

INPUTBOX
60
465
130
525
greg-vision
5.0
1
0
Number

INPUTBOX
0
527
107
587
minimum-separation
0.75
1
0
Number

INPUTBOX
134
465
215
525
max-align-turn
30.0
1
0
Number

INPUTBOX
218
464
315
524
max-cohere-turn
25.0
1
0
Number

INPUTBOX
318
463
433
523
max-separate-turn
1.0
1
0
Number

SLIDER
121
532
293
565
bite-size
bite-size
0.5
3
1.0
0.5
1
NIL
HORIZONTAL

INPUTBOX
436
462
520
522
max-food-turn
20.0
1
0
Number

SLIDER
380
76
555
109
rain-interval
rain-interval
0
700
425.0
25
1
ticks
HORIZONTAL

TEXTBOX
184
441
334
459
Behavioural Parameters
13
0.0
1

SLIDER
201
113
373
146
encounter-limit
encounter-limit
0
50
30.0
5
1
NIL
HORIZONTAL

@#$#@#$#@
# Model of Spatial Dynamics of Desert Locust Populations


## WHAT IS IT?

The locusts species __Schistocerca gregaria__ has two lifestyle phases to deal with environmental changes that exhibit their own behavior. They live on grass patches in the desert. High density populations will trigger a phase change and "gregarious" locusts appear. They form swarms and search the desert for food. When they find a grass patch they will land and start to eat. After distributing over the patch the phase change may trigger again as the density reduces. Then "solitary" locusts will roam the area on their own looking for food.  


## HOW IT WORKS

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
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="average lifepan of system" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count locusts-solitary</metric>
    <metric>count locusts-gregarious</metric>
    <metric>report-grass</metric>
    <enumeratedValueSet variable="max-separate-turn">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-grass-amount">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-food-turn">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-patches">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="greg-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bite-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rain-interval">
      <value value="425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cohere-turn">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movement-cost">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grass-regrowth-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soli-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-of-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-age">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-locusts">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-align-turn">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="default-system" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>ticks</metric>
    <metric>count locusts-solitary</metric>
    <metric>count locusts-gregarious</metric>
    <metric>report-grass</metric>
    <enumeratedValueSet variable="max-separate-turn">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-grass-amount">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-food-turn">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-patches">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="greg-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bite-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rain-interval">
      <value value="425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cohere-turn">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movement-cost">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grass-regrowth-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soli-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-of-patch">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-age">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-locusts">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-align-turn">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
