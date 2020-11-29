;extensions [profiler]

globals [
  access-task
  initial-0-employees
  rank ;; tells clients if this company is good enough(acc to their calculations) to work with ;; related to willingness
]

breed [ employees employee ]
breed [ clients client ]
breed [ tasks task ]
breed [ resources resource ]

employees-own [
  competence
  tasks-assigned
  tasks-dealt-with
  tasks-solved
  tasks-unsolved
  ability
  role
  worked-on?
  dim-understood
  IA ;; resource immediateness x ability
  following
  team?
  behaviour ;; normal distribution mean=0, sd=0.08
  resign-prob
  fire-prob
  team-satisfaction
  missed-resources
  stress
]

clients-own [
  strictness
  willingness
]

tasks-own [
  difficulty
  time-o
  time
  category
  ;  worked-on?
]

resources-own [
  dimensions ;; how versatile a resource is, higher number of dimensions means it can be used in multiple cases
  immediateness ;; how easy it is to use
  availability  ;; whether there is some clearance needed before one could use the resource
  misplaced? ;; if true, it means that the resource is no more in the hands of the employee
  following
]

to setup
  clear-all
  reset-ticks
  ;profiler:reset

  setup-global
  setup-employees
  setup-tasks
  setup-resources

  ;profiler:start
end

;; modified
to setup-global
  set rank comp-init-rank
end

to setup-employees
  crt num_employees / 5 [
    setxy random-xcor random-ycor
    set color white
    set size 1.5
    set breed employees
    set shape "person"
    set resign-prob random-float 0.2
    set fire-prob random-float 0.1
    set competence random-normal competence_mean 0.5
    set ability random-normal ability_mean 0.25
    set role 3
    ;
    set team? 1
    set tasks-assigned 0
    set tasks-solved 0
    set tasks-unsolved 0
    set tasks-dealt-with 0
    set behaviour random-normal 0 0.08
    set team-satisfaction 0
    set missed-resources 0
    set stress 0
  ]

  crt num_employees / 10 [
    setxy random-xcor random-ycor
    set color gray
    set size 1.5
    set breed employees
    set shape "person"
    set resign-prob random-float 0.2
    set fire-prob random-float 0.1
    set competence random-normal competence_mean 0.5
    set ability random-normal ability_mean 0.25
    set role 1
    ;
    set team? 1
    set tasks-assigned 0
    set tasks-solved 0
    set tasks-unsolved 0
    set tasks-dealt-with 0
    set behaviour random-normal 0 0.08
    set team-satisfaction 0
    set missed-resources 0
    set stress 0
  ]

  crt num_employees - count employees [
    setxy random-xcor random-ycor
    set color yellow
    set size 1.5
    set breed employees
    set shape "person"
    set resign-prob random-float 0.2
    set fire-prob random-float 0.1
    set competence random-normal competence_mean 0.5
    set ability random-normal ability_mean 0.25
    set role 0
    ;
    set team? 1
    set tasks-assigned 0
    set tasks-solved 0
    set tasks-unsolved 0
    set tasks-dealt-with 0
    set behaviour random-normal 0 0.08
    set team-satisfaction 0
    set missed-resources 0
    set stress 0
  ]

  set initial-0-employees count employees with [role = 0]
end

to setup-tasks
  crt initial-0-employees * proportion-tsk/prt [
    setxy random-xcor random-ycor
    set color red
    set size 1.5
    set breed tasks
    set shape "square 2"
    set difficulty min_difficulty + (random-float (1.01 - min_difficulty))
    set time-o random 5
    set time time-o
    set category random (task_categories + 1)
  ]
end

to setup-resources
  crt initial-0-employees * proportion-rsr/prt [
    setxy random-xcor random-ycor
    set color green
    set size 1.5
    set breed resources
    set shape "triangle"
    set dimensions random 3 ;; three levels: if 2 it can be used with any task, if 1 only some, if 0 only a very limited #
                            ;; also, higher levels allow the same resource to be used by multiple employees
    set immediateness random-normal mean_immediateness 1 ;; if < 0 then it requires more work --- an employee should stick to it
  ]
  ask n-of (num_employees * proportion-rsr/prt * proportion-available_res) resources [
    set availability 1 ] ;; available or not available
end

to go
  if tasks-prt? or no-employees? [ stop ]

  ;; generates tasks with a frequency
  generate-tasks

  ;; updates rach tasks time for every tick
  update-tasks-time

  ;; handles the movement of all agents
  move

  ;; checks the limit of the task which is 5.
  check-employees-limit

  ;; checks the limit of the task which is 10.
  check-tasks-limit

  attach-tasks
  attach-resources

  activate

  perform-1

  tick

  ;;hire-employees
end

;; reports tasks proportion
to-report tasks-prt?
  report count tasks / (num_employees * proportion-tsk/prt) <= 0.01
end

;; reports true or false count of employees
to-report no-employees?
  report count employees <= 10
end

;; generates tasks
to generate-tasks
  if tasks_waves and ticks mod 10 = 0 [
    let ran-regenerate-tasks random (num_employees * proportion-tsk/prt) / 2
    if count tasks < (num_employees * proportion-tsk/prt) - ran-regenerate-tasks [
      let _tasks-count (random ran-regenerate-tasks) + (ran-regenerate-tasks / 4)
      while [_tasks-count > 0]
      [
        ask one-of tasks
        [
          hatch 1 [
            setxy random-xcor random-ycor
            set color red
          ]
        ]
        set _tasks-count _tasks-count - 1
      ]
    ]
  ]
end

;; function for updating team-satisfaction variable of employee
to update-teamsatisfication
  ask employees with [role = 0] with [any? my-links with [color = orange]] [
    let sum-bev 0
    ask turtle-set [other-end] of my-links with [color = orange] [
      set sum-bev sum-bev + behaviour
    ]
    set team-satisfaction team-satisfaction + random-normal (sum-bev / count turtle-set [other-end] of my-links with [color = orange]) 0.01
  ]
end

;; function for updating resign probability
to update-resign-prob
  if ticks mod 100 = 0 [
    ask employees with [role = 0] [
      set resign-prob resign-prob + ((0.4 * stress) - (0.6 * team-satisfaction)) / 100

      ifelse resign-prob >= 1 [
        if any? my-links
        [
          ask my-links [ die ]
        ]
        die
      ] [
        ifelse resign-prob >= 0 [
          if random-normal resign-prob 0.1 >= 1 [
            if any? my-links
            [
              ask my-links [ die ]
            ]
            die
          ]
        ]
        [ set resign-prob 0 ]
      ]
    ]
  ]
end

;; to handle the probability to fire an employee
to update-fire-prob
  if ticks mod 100 = 0 [
    ask employees with [role = 0] with [ tasks-dealt-with > 0] [
      set fire-prob fire-prob - ((
        (tasks-solved / 9) - tasks-unsolved) / (tasks-dealt-with * 10) + (behaviour / (behaviour + 2)  ;; based on number of tasks solved, unsolved and behaviour of employee
                                                                                                       ;; fire-prob will increase or decrease accordingly
      ))

      ifelse fire-prob >= 1 [
        if any? my-links
        [
          ask my-links [ die ]
        ]
        die
      ] [
        ifelse fire-prob >= 0 [
          if random-normal fire-prob 0.1 >= 1 [
            ;  show self
            if any? my-links
            [
              ask my-links [ die ]
            ]
            die
          ]
        ]
        [ set fire-prob 0 ]
      ]
    ]
  ]
end

;; hiring employees
to hire-employees
  if ticks mod 100 = 0 [
    let cr-empls-count count employees with [role = 0]
    ask one-of employees with [role = 0] [
      hatch (initial-0-employees - cr-empls-count) [
        setxy random-xcor random-ycor
        set resign-prob random-float 0.2
        set fire-prob random-float 0.1
        set competence random-normal competence_mean 0.5
        set ability random-normal ability_mean 0.25
        set role 0
        ;
        set team? 1
        set tasks-assigned 0
        set tasks-solved 0
        set tasks-unsolved 0
        set tasks-dealt-with 0
        set behaviour random-normal 0 0.08
        set team-satisfaction 0
        set missed-resources 0
        set stress 0

        if any? my-links [ ask my-links [die] ]
      ]
    ]
  ]
end
;

to update-tasks-time
  ask tasks with [any? my-links] [
    set time-o time-o - 0.1
    if time-o <= 0 [
      ask my-links with [ [breed] of other-end = employees ]
      [
        ask other-end
        [
          if any? my-links
          [ ask my-links [die] ]
          set team? 1
          set missed-resources missed-resources + 1
        ]
        if self != nobody [die]
      ]
      setxy random-xcor random-ycor
      set color red
      set time-o time

      ;; update fire and resign probabilities
      update-fire-prob
      update-resign-prob
    ]
  ]
end

to move
  ask turtles [
    if abs xcor > 49 or abs ycor > 49 [
      setxy random-xcor / 2 random-ycor / 2
    ]
  ]

  ;; DS 27 aug 2019: rewritten to make tasks fixed
  ask employees with [role = 0] with [ count my-links with [color = yellow] = 0 ] [
    if any? my-links
    [
      ask my-links [die]
    ]

    ifelse following = 0 [
      ifelse any? tasks in-radius radius
      [
        face one-of tasks in-radius radius
        set following 1
        fd speed_fd
      ]
      [ rt random 360 ]
    ]
    [ fd speed_fd ]
  ]

  ask resources
  [
    ifelse count my-links with [color = yellow] = 0
    [ fd speed_fd ]
    [ rt random 360 ]
  ]
end

to check-employees-limit
  ask links with [color = yellow] [
    ask end2 [
      let extra-links count my-links - 10
      if count my-links > 10 [
        ask n-of extra-links my-links [ die ]
      ]
    ]
  ]
end

to check-tasks-limit
  ask links with [color = yellow] [
    ask end1 [
      let extra-links count my-links with [color = yellow] - 5
      set stress stress + extra-links / 10000
      if count my-links with [color = yellow] > 5 [
        ask n-of extra-links my-links with [color = yellow] [ die ]
      ]
    ]
  ]
end

to attach-tasks
  ask employees with [role = 0] [
    ifelse any? my-links []
    [
      create-links-with tasks in-radius proximity
      [
        set color yellow
        ask end1 [
          set tasks-assigned tasks-assigned + 1
        ]
      ]
      set following 0
    ]
  ]
end

to attach-resources
  ask employees with [role = 0] [
    if any? my-links with [color = yellow] [
      create-links-with resources in-radius proximity
      [ set color green ]
      ask resources in-radius proximity [ set following 0 ]
      ; ask resources [ ask my-links [ set color green ] ]
    ]
  ]
end

to activate
  ask links with [ color = green ] [
    if [role] of end1 = 0 and [availability] of end2 = 0 [
      ask self [ die ]
      ask end2 [ jump proximity + 2 ]
    ]
    if link-length > proximity [ die ]
  ]

  ask links with [color = yellow] [
    if link-length > proximity [ die ]
  ]
end


to perform-1
  ;ask employees with [role = 0] [
  ;  let comp-standardized ([competence] of self) / (max [competence] of employees)
  ;  set dim-understood comp-standardized * sum [dimensions] of resources in-radius proximity with [any? links]
  ;] ;; the extent to which an employee understands the multi-dimensionality of resources available

  ;; DS 26 august 2019: I have rewritten the code according to what explained in the Info section --
  ;; it seems to work fine this way and, frankly, it makes more sense now.

  ask employees with [role = 0] [
    let hi-co mean [competence] of employees + standard-deviation [competence] of employees
    let lo-co mean [competence] of employees - standard-deviation [competence] of employees


    ifelse any? ((turtle-set [other-end] of my-links with [color = green]) with [dimensions = 2]) and
    [competence] of self >= hi-co [
      ask (turtle-set [other-end] of my-links with [color = yellow]) [
        set color yellow ;; this would be 45 (DS 26 aug 2019)
      ]
      set tasks-dealt-with tasks-dealt-with + count (turtle-set [other-end] of my-links with [color = yellow]) with [color = 45]
      set worked-on? 45
    ]
    [
      ifelse any? ((turtle-set [other-end] of my-links with [color = green]) with [dimensions = 1]) and
      any? ((turtle-set [other-end] of my-links with [color = yellow]) with [difficulty <= 0.75]) and
      [competence] of self > lo-co
      [
        ask ((turtle-set [other-end] of my-links with [color = yellow]) with [difficulty <= 0.75]) [
          set color 46
        ]
        set tasks-dealt-with tasks-dealt-with + count (turtle-set [other-end] of my-links with [color = yellow]) with [color = 46]
        set worked-on? 46
      ]
      [
        if any? ((turtle-set [other-end] of my-links with [color = green]) with [dimensions = 0]) and
        any? ((turtle-set [other-end] of my-links with [color = yellow]) with [difficulty <= 0.25])
        [
          ask ((turtle-set [other-end] of my-links with [color = yellow]) with [difficulty <= 0.25]) [
            set color 47
          ]
          set tasks-dealt-with tasks-dealt-with + count (turtle-set [other-end] of my-links with [color = yellow]) with [color = 47]
          set worked-on? 47
        ]
      ]
    ]
  ]

  ;; forms teams within employees assigned to same task
  form-team

  ;; DS 23 aug 2019: I think there is a problem with the dim-understood measure, it is too broad and
  ;; too high (or too low), it needs to be standardized. Even the mean is too high, if it needs to be
  ;; compared to any of the characteristics of the problems.


  ;; DS 23 aug 2019: the duplication of the code below does not make sense because end1 is always
  ;; an employee and end2 is always a resource or a task.

  ;; DS 27 aug 2019: I am not so sure I want to keep the category, right now, I have the
  ;; impression the simulation is already too complex. I leave this out for now.

  perform-2

end

to perform-2
  ;; DS 23 aug 2019: some of the problems of the code above relate to the
  ;; number of links that an employee has. IA seems to be calculated with
  ;; one only of the resources available. The way to select one of them
  ;; is not clear to me. What if there are more than one resources available?
  ;; There are different options here:
  ;; (1) select one-of the resources, randomly
  ;; (2) select the best IA out of those available
  ;; (3) select a combination of those IA that seem suitable
  ;; (4) select an average of IAs

  ;; DS 26-27 aug 2019: given the above, below is the new code

  ask links with [color = yellow] [
    if [worked-on?] of end1 = [color] of end2 [
      ask end1 [
        let res-available (turtle-set [other-end] of my-links with [color = green])
        if any? my-links with [color = green] [
          ifelse any? (res-available with [immediateness > 0])
          [
            ; ask (res-available with [immediateness > 0]) [ ask patch-here [ set pcolor 41 ] ]
            set IA ([ability] of self * [immediateness] of (one-of res-available with [immediateness > 0])) ;; random choice

            ;; DS 28 august 2019: code below added to increase competence of those who
            ;; perform well with tasks
            let _cmplt-task random-normal [behaviour] of self 0.03
            if _cmplt-task >= 0
            [
              if [IA] of self > [difficulty] of other-end and [difficulty] of other-end > 0.75
              [
                set competence competence + competence_increase
              ]

              if [IA] of self > [difficulty] of other-end and [difficulty] of other-end <= 0.75 and
              [difficulty] of other-end > 0.25
              [ set competence competence + (competence_increase / 2) ]

              if [IA] of self > [difficulty] of other-end and [difficulty] of other-end <= 0.25
              [ set competence competence + (competence_increase / 10) ]
            ]
            if [IA] of self > [difficulty] of other-end
            [
              ifelse _cmplt-task >= 0
              [
                ask other-end
                [
                  ; ask patch-here [ set pcolor 41 ]
                  die
                ]
                set tasks-solved tasks-solved + 1
              ]
              [
                ask other-end
                [
                  ask my-links [ die ]
                  setxy random-xcor random-ycor
                  set color red
                  set time-o time-o + 1
                ]
                set tasks-unsolved tasks-unsolved + 1
              ]

              ;; reset variables of employee
              set following 0
              set team? 1
              set worked-on? 0
              set heading random 360
              fd speed_fd

              ;; updating team-satisfaction variable of employee agent
              if count turtle-set [other-end] of my-links with [color = orange] > 0 [
                let sum-bev 0
                ask turtle-set [other-end] of my-links with [color = orange] [
                  set sum-bev sum-bev + behaviour
                ]
                set team-satisfaction team-satisfaction + random-normal ((sum-bev / count turtle-set [other-end] of my-links with [color = orange]) / 1000) 0.01
              ]

              ;; update fire and resign probabilities
              update-fire-prob
              update-resign-prob

              ;;
              ask my-links with [color = green] [
                ask end2 [jump proximity * 2]
                die
              ]
              if any? my-links with [color = orange]
              [
                ask my-links with [color = orange] [ die ]
              ]
            ]
          ]
          [
            let differential2 ([ability] of self) / 10
            ask one-of res-available with [immediateness <= 0] [
              set immediateness immediateness + abs (immediateness * differential2)
            ]
          ]
        ]
      ]
    ]
  ]
end

;; to form teams within employees
to form-team
  ask employees with [role = 0] [
    if all? my-links [color = orange] [
      ask my-links [ die ]
      set team? 1
      jump proximity * 2
    ]
  ]

  ask tasks with [ count my-links with [color = yellow] > 1 ] [
    let empls (turtle-set [other-end] of my-links with [color = yellow]) with [team? = 1]
    ask empls [
      let empl self
      ask empls [
        if self != empl [
          create-link-with empl [ set color orange ]
        ]
      ]
      set team? 0
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
639
12
1161
535
-1
-1
5.09
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
429
13
495
46
NIL
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
499
13
563
46
go!
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

BUTTON
568
13
631
46
NIL
go
NIL
1
T
OBSERVER
NIL
H
NIL
NIL
1

SLIDER
26
39
198
72
num_employees
num_employees
0
500
500.0
50
1
NIL
HORIZONTAL

SLIDER
232
102
404
135
task_categories
task_categories
0
5
1.0
1
1
NIL
HORIZONTAL

INPUTBOX
201
12
310
72
proportion-tsk/prt
3.0
1
0
Number

SLIDER
288
329
460
362
proximity
proximity
0
15
7.0
1
1
NIL
HORIZONTAL

INPUTBOX
313
12
421
72
proportion-rsr/prt
0.5
1
0
Number

MONITOR
618
588
695
633
res-links
count links with [ color = green ]
0
1
11

SLIDER
415
102
626
135
proportion-available_res
proportion-available_res
0
1
0.32
0.01
1
NIL
HORIZONTAL

MONITOR
459
588
516
633
#tasks
count tasks
17
1
11

PLOT
22
369
418
535
IA, ability, and competence
Time
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"IA_levels" 1.0 0 -1184463 true "" "if ticks > 0 [ plot mean [IA] of employees ]"
"IA_HiDoc" 1.0 0 -955883 true "" "if ticks > 0 [ plot mean [IA] of employees with [docility > mean [docility] of employees] ]"
"comp_levels" 1.0 0 -7500403 true "" "if ticks > 0 [ plot mean [competence] of employees ]"
"diff_tsks" 1.0 0 -14439633 true "" "if ticks > 0 [ plot mean [difficulty] of tasks ]"

SLIDER
288
294
461
327
frequency_interactions
frequency_interactions
0
15
10.0
1
1
NIL
HORIZONTAL

MONITOR
520
588
614
633
#tasks-dealt
mean [tasks-dealt-with] of employees
17
1
11

PLOT
18
537
412
706
Talks solved and dealt with
Time
#tasks
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"tasks-sys" 1.0 0 -16777216 true "" "plot count tasks"
"tasks-dw" 1.0 0 -7500403 true "" "plot sum [tasks-dealt-with] of employees"
"tasks-wkd" 1.0 0 -2674135 true "" "if ticks > 0 [ plot mean [worked-on?] of employees ]"

MONITOR
617
540
695
585
#tasks-yel
count tasks with [color = yellow] +\ncount tasks with [color = 46] +\ncount tasks with [color = 47]
2
1
11

SWITCH
142
294
278
327
look-for-tasks
look-for-tasks
1
1
-1000

MONITOR
460
637
517
682
#empl
count employees
0
1
11

MONITOR
459
540
516
585
#res
count resources
0
1
11

SWITCH
142
328
278
361
ticks=ON
ticks=ON
0
1
-1000

MONITOR
520
540
614
585
#tsks-solved
sum [tasks-solved] of employees
0
1
11

SLIDER
232
137
404
170
min_difficulty
min_difficulty
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
415
137
627
170
mean_immediateness
mean_immediateness
-1
1
1.0
0.1
1
NIL
HORIZONTAL

SWITCH
26
245
159
278
tasks_waves
tasks_waves
0
1
-1000

SLIDER
162
245
334
278
hit_wave
hit_wave
0
0.5
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
23
102
220
135
competence_mean
competence_mean
0
3
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
23
170
220
203
ability_mean
ability_mean
0
5
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
23
204
220
237
ability_increment_for_HiDoc
ability_increment_for_HiDoc
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
23
136
220
169
competence_increase
competence_increase
0
1
0.2
0.01
1
NIL
HORIZONTAL

PLOT
420
369
633
535
Ability plot
Time
Ability
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"ability_change" 1.0 0 -16777216 true "" "if ticks > 0 [ plot mean [ability] of employees ]"

TEXTBOX
25
279
175
297
General conditions
11
105.0
1

TEXTBOX
27
17
214
45
Number of agents in the system
11
75.0
1

TEXTBOX
26
86
176
104
Employee characteristics
11
44.0
1

TEXTBOX
235
86
385
104
Task characteristics
11
14.0
1

TEXTBOX
422
86
572
104
Resource characteristics
11
64.0
1

SLIDER
598
688
770
721
speed_fd
speed_fd
0
2
0.1
0.1
1
NIL
HORIZONTAL

PLOT
1163
535
1363
685
Employee_plot
ticks
employees count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"employees" 1.0 0 -16777216 true "" "plot count employees"

SLIDER
1169
11
1341
44
comp-init-rank
comp-init-rank
0
1
0.2
0.001
1
NIL
HORIZONTAL

SLIDER
1168
46
1343
79
min-willingness-client
min-willingness-client
0
1
1.0
0.001
1
NIL
HORIZONTAL

SLIDER
1247
143
1419
176
radius
radius
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
1184
202
1356
235
behaviour-update-freq
behaviour-update-freq
0
50
50.0
5
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

IOP 2.1.2 is an agent-based simulation model designed to explore the relations between (1) employees, (2) tasks and (3) resources in an organizational setting. By comparing alternative cognitive strategies in the use of resources, employees face increasingly demanding waves of tasks that derive by challenges the organization face to adapt to a turbulent environment. The assumption tested by this model is that a successful organizational adaptation, called plastic, is necessarily tied to how employees handle pressure coming from existing and new tasks. By comparing alternative cognitive strategies, connected to ‘docility’ (Simon, 1993; Secchi, 2011) and ‘extended’ cognition (Clark, 2003, Secchi & Cowley, 2018), IOP 2.1.2 is an attempt to indicate which strategy is most suitable and under which scenario.

## HOW IT WORKS

There are different agents in this simulation: employees, tasks, resources. Employees are those who populate the organization, deal with tasks by using their own characteristics and exploiting resources.

### Employee characteristics
They are distributed randomly in the system and their total number of employees (person shape, yellow) in the system is set by the slider <i>num_employees</i>. Each agent is assigned the following:
<ul>
<li><b>competence</b> Distributed random-normally with mean = 1 and standard deviation = 0.5, it is the level of professionalism that is relevant to the task/job.</li>
<li><b>ability</b> Distributed random-normally with mean = 1 and standard deviation = 0.25, it is the level of aptness that a participant is capable of exercizing.</li>
<li><b>role</b> Distributed as random 2, such that there are only two levels possible for employees -- one may think of this either as different specializations or as a hierarchical distinction between managers and employees.</li>
<li><b>docility</b> Distributed random-normally with mean = 1 and standard deviation = 0.5, it is the attitude with which one is willing to cooperate with and use information from others.</li>
</ul>

### Task features
They are distributed randomly in the simulation space and their total number of task (square shape, red) s in the system is set by the input box <i>proportion-tsk/prt</i>, and it should be read as the number of tasks available per participant. So, for example, the number 2 in the box means that tasks are twice the number of employees. Each agent is assigned the following:
<ul>
<li><b>difficulty</b> Distributed with a random-float 1.01 function, it represents how hard a task is to carry to its end.</li>
<li><b>time</b> Distributed with a random 5 function, it is the amount of time available for an employee to deal with the task. Once it expires, the link with the employee disappears and the time is restored to its original status, ready for the next to deal with the task.</li>
<li style="color:blue;"><b>category</b> This is a definition of the domain to which the task pertains and is assigned using the slider <i>task_categories</i>. The distribution takes the slider's input as an upper bound for a random number to be assigned to the task agent. <b>CURRENTLY NOT IN USE</b></li>
</ul>

### Resources
The total number of resources (triangle shape, green) in the system is set by the input box <i>proportion-rsr/prt</i>, and it should be read as the number of resources available per participant. So, for example, the number 3 in the box means that tasks are three times the number of employees. Each agent is assigned the following:
<ul>
<li><b>dimension</b> Distributed with a random 3 function, so that there are three levels. If the assigned number is 2 then the resource can be used with any task, if 1 only some, if 0 it has a very limited use; also, higher levels of this characteristic allow the same resource to be used by multiple employees.</li>
<li><b>immediateness</b> Distributed with a random-normal function with mean = 0 and standard deviation = 1, it is the accessibility of the given resource. Low levels indicate that an employee should work on the resource for longer time before having it available.</li>
<li><b>availability</b> By using the slider <i>proportion-available_res</i> one can set the percentage of resources that are actually available for employees to use. There are some that are in the system but stay unlocked until something happens (see below).</li>
</ul>

## HOW TO USE IT

In the following, procedures are briefly described, to give an idea of what happens in the model when the <b>GO</b> button is clicked.

#### stop300
This switch makes the system stop after 300 ticks (interactions).

#### save_it
If switched to ON, this command saves three csv files with every single bit of information available in the model. The first file is saved after 100, the second after 200, and the third after 300 ticks.

#### ticks
As usual in these types of simulations, time is counted by the <b>ticks</b>, visible in the upper center section of the Interface. Every time a unit (a tick) is counted, the task that is set to be solved -- i.e. that is liked to an employee -- will be counting down at a rate of 0.1 at every tick (remember each task has an expiration time that could be a number between 0 to 4.

#### frequency_interactions
This slider sets the time with which employees connect with close tasks (defined by the <i>proximity</i> slider). So, every x seconds, set by the slider, employees connect with close tasks and, at the same time, put a few actions in place, namely they 'move' together (see below) and find appropriate resources to use. These resources are found and linked to if they are in range of <i>proximity</i>. Links with resources are green.

#### tasks_wave & hit_wave
The switch and the slider are to mimic <b>dramatic change</b> in unpredictable  environments. At every <i>X</i> seconds, defined by the slider <i>frequency_interactions</i>, a wave of new tasks ''invades'' the space, at a rate defined by the <b>hit_wave</b>, and calculated as a percentage of the number of tasks initially in the system.

#### Look for tasks
The switch makes employees who are 'free' of any task face a random one in the system and move towards it (forward = 0.1). 

#### ticks=ON
This is to makes it such that action happens at every tick as opposed to every number of seconds as set by the slider <i>frequency_interactions</i>.

### Moving
In the simulation, every agent has a slightly different moving pattern.

By default, every agent with no association to a link moves 0.1 steps (i.e. patches) forward in the direction it is facing at the moment. When an agent has a link to other agents, then they tend to move together, according to a attraction/repulsion algorithm.

### Activation and task performance
As anticipated above, the resource needs to have <b>availability</b> > 0. When an employee with <b>role</b> = 0 is connected to a resource with <b>availability</b> = 1 then the link between the two breaks because the employee does not have access to it.

Every employee has a basic understanding of resource multi-dimensionality, and that is driven by the employee's competence, such that the number of dimension understood is the sum of the dimensions of the resources to which the employee is connected times its own competence. If the number of dimensions understood are higher than the category of a task, then it will be possible to deal with it.
In the following step, each employee calculates possible actions. This is a coefficient obtained by multiplying the employee's <i>ability</i> with the <i>immediateness</i> of the resource. When IA > difficulty of the task, then it is solved. At the same time, the solution leaves a mark and a patch becomes dark yellow (the change of color can be observed in the environment).
When IA > difficulty but it is also IA > (mean IA + st.dev. IA) of all the employees in the system, then the task is dealt with as well. In the opposite case when IA < difficulty and also IA < (mean IA - st.dev. IA) of all employees, then the difficulty of the problem decreases slightly of 1/10th of the employee's ability. Finally, when IA is in the middle of the distribution (mean +/- st.dev.) then the difficulty of the problem decreases of 1/5th of the employee's ability.


### Cognitive fit
The final part of executing the task is that of bringing in cognition. This is done for employees depending on their <i>docility</i> standing. The switch that enables <b>distributed cognition</b> is called <i>dc-simulate</i> in the Interface tab. When this is ON, then employees explore the area around them (using <i>proximity</i>) and perform some actions if there are areas with a color different from black (that indicates that a task has been dealt with). When that is the case, then the employee and the resources to which it is connected leave a dark lime impression on the patches underneath them. If there are dark lime colored patches, the employee would move towards them (forward 0.5).

When the switch is OFF, then the behavior is different. If the color of the patches around (same as above, using <i>proximity</i>) is different from black then the links with the resources are broken and both agents move abruptly away from that area (the command here is 'jump 2').

Another switch that is related to this procedure is the <i>docility_enabler</i>. This allows for the use of so-called 'social resources'. When the docility of an employee is higher than the average docility value, then this highly docile employee will establish connections with other employees in the vicinity (usual spacial reference with the <i>proximity</i> parameter). These links can be visualized in the environment because their color is orange. These connections affect IA, that has a 20% increase weighted on the number of other highly docile employees.


## THINGS TO NOTICE

When tasks become overwhelming the interface becomes very difficult to read. But it looks beautiful! Most things to notice are described in the Supplementary Materials file.


## EXTENDING THE MODEL

The model could be implemented with cognitive strategies from the distributive framework other than enacted and extended. It could also identify different decision making mechanisms other than dicility/bounded rationality.


## RELATED MODELS

The model closer to this are others that implement docility mechanisms, from:
<ul>
<li> inquisitiveness: <a href="url">https://www.comses.net/codebases/4749/releases/1.0.0/</a></li>
<li> intra-organizational bandwagon: <a href="url"> https://www.comses.net/codebases/4716/releases/1.0.0/</a> </li>
</ul>

## CREDITS AND REFERENCES

The paper in which this model is discussed is:
Secchi, D. (forthcoming). Cognitive attunement in the face of organizational plasticity. Evidence-Based Human Resource Management.

### Other references:
Clark, A. (2003), <i>Natural-born Cyborgs. Minds, Technologies, and the Future of Human Intelligence</i>, Oxford University Press, Oxford.

Secchi, D. and Cowley, S.J. (2018), “Modeling organizational cognition: the case of impact factor”, <i>Journal of Artificial Societies and Social Simulation</i>, Vol. 21 No. 1, p. 13.

Secchi, D. (2011), <i>Extendable Rationality. Understanding Decision Making in Organizations</i>, Springer, New York, NY.

Simon, H.A. (1993), “Altruism and economics”, <i>American Economic Review</i>, Vol. 83 No. 2, pp. 156-161.
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="trial-cal" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_mean">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-tsk/prt">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calibration_3.0.0" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="main_exp" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-rsr/prt">
      <value value="0.5"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_mean">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-tsk/prt">
      <value value="0.5"/>
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calibration_3.0.2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_3.1.1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_3.1.2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_3.2.1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_3.2.2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_4.0.1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_4.0.2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_4.1.1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_4.1.2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_4.2.1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="calibration_4.2.2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-rsr/prt" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="competence_mean" first="0.5" step="0.5" last="2"/>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proportion-tsk/prt" first="0.5" step="0.5" last="2"/>
  </experiment>
  <experiment name="main_exp_2" repetitions="15" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <exitCondition>count tasks / (num_employees * proportion-tsk/prt) &lt;= 0.1</exitCondition>
    <metric>count tasks</metric>
    <metric>sum [tasks-solved] of employees</metric>
    <metric>mean [tasks-dealt-with] of employees</metric>
    <metric>sum [tasks-dealt-with] of employees</metric>
    <metric>count tasks with [color = 45] + count tasks with [color = 46] + count tasks with [color = 47]</metric>
    <metric>sum [tasks-solved] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees</metric>
    <metric>mean [competence] of employees</metric>
    <metric>mean [IA] of employees</metric>
    <metric>mean [difficulty] of tasks</metric>
    <metric>mean [competence] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [ability] of employees with [docility &gt; mean [docility] of employees]</metric>
    <metric>mean [IA] of employees with [docility &gt; mean [docility] of employees]</metric>
    <enumeratedValueSet variable="save_it">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks=ON">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-rsr/prt">
      <value value="0.5"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasks_waves">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dc-simulate">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_employees">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="task_categories">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_increment_for_HiDoc">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="look-for-tasks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_increase">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="docility-enabler">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_immediateness">
      <value value="-0.5"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="competence_mean">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_difficulty">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hit_wave">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frequency_interactions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-available_res">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed_fd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop300">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proximity">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability_mean">
      <value value="0.05"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-tsk/prt">
      <value value="0.5"/>
      <value value="2"/>
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
