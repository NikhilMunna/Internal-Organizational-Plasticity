;; GLOBAL VARIABLES
globals [
  ;; for s1, s2, s3
  gamma1
  gamma2
  gamma3
  ;; for ability
  psi1
  psi2
  psi3
  psi4
  psi5

  alpha ;; GLOBAL PENALTY PARAMETER USED IN CALCULATION OF TASK WORKLOAD
  ;; AVERAGE TEAM SIZE OVERTIME
  avg-team-size
  ;; COUNT OF # TIMES NO TEAM WAS FORMED
  no-team-count
  avg-no-team-time ;; AVERAGE TIME IN WHICH ANY TEAM MANAGER WAS IDLE
  ;; EMPLOYEE AGENT WHO IS SELECTED FOR PROMOTION
  promote-emp
  check-prom ;; BOOLEAN TO CHECK FOR PROMOTION
]

;; BREEDS DECLERATION
breed [ employees employee ]
breed [ tasks task ]
breed [ resources resource ]

;; BREEDS VARIABLES DECLERATION
employees-own [
  ;;
  #days-worked
  tasks-dw ;; NUMBER OF TASKS DEALT WITH (AS A TEAM FOR TEAM MANAGER)
  tasks-solved
  avg-resources-delay
  avg-task-life
  role
  team?
  task-id
  #teams-formed
  no-team-time
  ;;
  opportunity
  commitment
  performance
  ;; PERSONAL ATTRIBUTES
  ability
  knowledge
  resign-prob
  fire-prob
  team-satisfaction ;; DEPENDS ON THE WORK CONTRIBUTION OF OTHER TEAM MEMBERS WHEN WORKING WITH THE TEAM
  stress
  ;; MOTIVATOIN PARAMETERS
  s1 ;; ACHIEVEMENT
  s2 ;; AFFILIATION
  s3 ;; POWER
  w-c ;; WORK CONTRIBUTION
  e1 ;; EXPERIENCE WITH EASIER TASKS
  e2 ;; EXPERIENCE WITH MEDIUM LEVEL OF TASKS
  e3 ;; EXPERIENCE WITH HARDER TASKS
  ;; REPRESENTS THAT THIS EMPLOYEE CAN BE TEAM MANAGER
  tm-prom-days
]
tasks-own [
  difficulty
  t-l
  t-s ;; TASK STATUS (0-open, 1-active, 2-completed)
  p1
  p2
  p3
  #w-n
  task-wl
  team-c
]
resources-own [
  dimension ;; DECIDES WHO CAN USE THIS RESOURCE (1-INDIVIDUAL, 2-SMALL TEAM, 3-BIG TEAM)
            ;; SMALL TEAM - LESS THAN avg-team-size || BIG TEAM - GREATER THAN abg-team-size
]

;; MAIN SETUP FUNCTION
to setup
  clear-all
  reset-ticks
  setup-plots
  setup-global
  setup-employees
  setup-resources

end

;; SETTING UP GLOBAL VARIABLES
to setup-global
  ;; PROBABILITIES FOR MOTIVE PROFILE DISTRIBUTION
  set gamma1 0.75
  set gamma2 0.75
  set gamma3 0.75
  ;; PROBABILITIES FOR EMPLOYEE ABILITY IN RANGE (1 - 5)
  set psi1 0.5
  set psi2 0
  set psi3 0
  set psi4 0
  set psi5 0.5
  ;; CONSTANT VALUE OF ALPHA USED FOR CALCULATING WORKLOAD
  set alpha (ln 0.5 / 14)
  ;; SET AVERAGE TEAM SIZE (9.5 AS PER THE CURRENT SIMULATION)
  set avg-team-size 10.7
  set no-team-count 0 ;; INITIALIZING COUNT OF # NO TEAMS
  set avg-no-team-time 0
  set promote-emp nobody ;; INITIALIZE WITH NOBODY
  set check-prom false
end

;; SETTING UP EMPLOYEES IN THE ENVIRONMENT
;; (newly added variables data is taken from https://www.kaggle.com/pavansubhasht/ibm-hr-analytics-attrition-dataset)
to setup-employees
  ;; SETTING UP EMPLOYEES
  create-employees #employees [
    setxy random-xcor random-ycor
    set color yellow
    set size 1
    set shape "person"
    set #days-worked 0
    set avg-resources-delay 0
    set avg-task-life 0
    set resign-prob 0
    set fire-prob 0
    set knowledge random-normal knowledge_mean knowledge-std
    set team-satisfaction 0
    set stress 0
    set commitment random-normal 2.729932 0.711561
    set performance 0
    set role 0 ;; REPRESENTS EMPLOYEE
    set team? true
    set tasks-dw 0
    set tasks-solved 0
    set task-id -1
    set #teams-formed 0
    ;; MOTIVE PROFILE DISTRIBUTION
    ifelse random-float 1 < gamma1 [ set s1 2.0 ] [ set s1 1.0 ]
    ifelse random-float 1 < gamma2 [ set s2 2.0 ] [ set s2 1.0 ]
    ifelse random-float 1 < gamma3 [ set s3 2.0 ] [ set s3 1.0 ]
    ;; ABILITY
    ifelse random-float 1 < psi1 [ set ability 1 ]
    [
      ifelse random-float 1 < psi2 [ set ability 2 ]
      [
        ifelse random-float 1 < psi3 [ set ability 3 ]
        [
          ifelse random-float 1 < psi4 [ set ability 4 ]
          [ set ability 5 ]
        ]
      ]
    ]
    ;; EXPERIENCE VARIABLES (EASY, MEDIUM, HARD) TASKS
    set e1 0
    set e2 0
    set e3 0
    ;; NUMBER OF CONSECUTIVE DAYS AN EMPLOYEE CAN BE TEAM MANAGER
    set tm-prom-days 0
  ]

  ;; COMPUTING REQUIRED VALUES FOR TEAM MANAGERS VARIABLES
  let comp-emp mean [knowledge] of employees + standard-deviation [knowledge] of employees
  let comt-emp-m mean [commitment] of employees
  let comt-emp-s standard-deviation [commitment] of employees
  ;; SETTING UP TEAM MANAGERS
  create-employees #team-managers [
    set color white
    set size 1
    set shape "person"
    set #days-worked 0
    set avg-resources-delay 0
    set resign-prob 0
    set fire-prob 0
    set knowledge random-normal comp-emp knowledge-std
    set team-satisfaction 0
    set stress 0
    set commitment random-normal (comt-emp-m + comt-emp-s) comt-emp-s
    set performance random-normal 3.153741 0.360824
    set role 1 ;; REPRESENTS TEAM MANAGER
    set team? true
    set tasks-dw 0
    set tasks-solved 0
    set task-id -1
    set #teams-formed 0
    ;; MOTIVE PROFILE DISTRIBUTION
    set s1 2.0
    set s2 2.0
    set s3 2.0
    ;; ABILITY
    ifelse random-float 1 < psi3 [ set ability 3 ]
    [
      ifelse random-float 1 < psi4 [ set ability 4 ]
      [ set ability 5 ]
    ]
    ;; EXPERIENCE VARIABLES (EASY, MEDIUM, HARD) TASKS
    set e1 1.0
    set e2 1.0
    set e3 1.0
  ]
  ;; POSITIONING TEAM MANAGERS IN ENVIRONMENT
  position-tm
end

;; SETTING UP RESOURCES IN THE ENVIRONMENT
to setup-resources
  ;;
  ;; RESOURCES FOR TEAM WITH TEAM SIZE LESS THAN avg-team-size
  create-resources 1 + ceiling #team-managers / 2 - (#team-managers / avg-team-size) [
    setxy random-xcor random-ycor
    set shape "pentagon"
    set color green
    set size 0.5
    set dimension 2
  ]
  ;;
  ;; RESOURCES FOR TEAM WITH TEAM SIZE GREATER THAN avg-team-size
  create-resources 1 + #team-managers - count resources [
    setxy random-xcor random-ycor
    set shape "pentagon"
    set color green
    set size 0.5
    set dimension 3
  ]
  ;;
  ;; RESOURCES FOR INDIVIDUALS
  ;;create-resources #employees - (#team-managers * avg-team-size) [
  ;;  setxy random-xcor random-ycor
  ;;  set shape "pentagon"
  ;;  set color green
  ;;  set size 0.5
  ;;  set dimension 1
  ;;]
end

;; SETTING UP A SINGLE TASK
to-report setup-task [_team?]
  let _task nobody
  create-tasks 1 [
    set shape "square 2"
    set color red
    set size 0.5
    ifelse _team? [set difficulty (random 100) + 1] ;; FOR TEAM
    [set difficulty (random 33) + 1] ;; FOR INDIVIDUAL
    set t-s 0
    set t-l 0
    ifelse _team? [set #w-n min-team-size + ([difficulty] of self / 25)] ;; FOR TEAM
    [set #w-n 1] ;; FOR INDIVIDUAL
    set p1 (100 - [difficulty] of self) / 100 ;; TASK'S PROBABILITY OF SUCCESS BASED ON THE DIFFICULTY VALUE
    set task-wl [difficulty] of self * (exp alpha * [t-l] of self)
    set team-c 0
    set _task self
  ]
  report _task
end

;; FUNCTION FOR RUNNING THE SIMULATION
to go
  ;; CREATION AND ASSIGNING OF TEAM TASKS
  create-assign-team-tasks
  ;; CREATION AND ASSIGNING OF INDIVIDUAL TASKS
  ;; create-assign-ind-tasks
  ;; ALLOCATION OF APPROPRIATE RESOURCES TO THE TASKS
  allocate-resources

  tick

  ;; FUNCTIONS TO BE RUN AFTER EVERY TICK
  ;; UPDATING TASKS AND EMPLOYEES ATTRIBUTES AT EACH TIME STEP
  update-tasks
  ;; UPDATING DAYS OF WORKED OF ALL EMPLOYEES
  update#days-worked
  ;; UPDATING OPPORTUNITY OF EVERY EMPLOYEE
  calc-opportunity
  ;; UPDATING NO TEAM ATTRIBUTES
  update-no-team-attrs
  ;; CALCULATION OF EMPLOYEE PERFORMANCE (DETAILS ARE LISED AS COMMENTS IN FUNCTION)
  ;; calc-emp-performance
  ;; PROMOTION CHECK
  emp-to-tm
  ;; PROMOTES WHEN THE EMPLOYEE IS FREE FROM ALL TASKS
  promote-when-free
  ;; PLOT ALL NEXESSARY VALUES
  plots

end

;; TEAM MANAGERS SELECTING THEIR TEAMS
to-report tm-select-teams [tm _task]
  let team nobody
  if (count employees with [role = 0 and team?]) >= ([#w-n] of _task) [
    ask tm [
      set team n-of ([#w-n] of _task) employees with [role = 0 and team?]
      let x [xcor] of self
      let y [ycor] of self
      create-links-with team [ set color white ]
      set team? false
      ask team [
        setxy (x + 2 * (sin random 360)) (y + 2 * (cos random 360))
        ;; ASSIGN THE TASK
        create-link-with _task [ set color yellow ] ;; LINK COLOR FOR EMPLOYEE TO TASK IS YELLOW (45)
        set task-id [who] of _task
        set #teams-formed #teams-formed + 1
        set tasks-dw [tasks-dw] of self + 1
      ]
      set #teams-formed #teams-formed + 1
      ;; CALCULATE AVERAGE TEAM SIZE FOR EACH TEAM FORMATION
      set avg-team-size ( ((avg-team-size * ((sum [#teams-formed] of employees with [role = 1]) - 1)) + count team) / sum [#teams-formed] of employees with [role = 1] )
      ;; CALCULATIONS OF NO TEAM TIME AND COUNT
      set no-team-count no-team-count + 1
      set avg-no-team-time ((avg-no-team-time * (no-team-count - 1)) + [no-team-time] of self) / no-team-count
      set no-team-time 0
    ]
  ]
  report team
end

;; UPDATE NO TEAM TIME AND COUNT
to update-no-team-attrs
  ask employees with [role = 1 and team?] [
    set no-team-time no-team-time + 1
  ]
end

;; CREATION AND ASSIGNING OF TASKS
to create-assign-team-tasks
  let loop? true
  let #tasks count employees with [role = 1 and task-id = -1]
  while [loop? and #tasks != 0] [
    let tm max-one-of (employees with [role = 1 and task-id = -1]) [no-team-time]
    ;; ASSIGN TASK TO THE TEAM MANAGER
    ;; SET POSITION OF THE TASK NEAR THE TEAM
    let x [xcor] of tm
    let y [ycor] of tm
    ask (setup-task true) [
      let team tm-select-teams tm self
      ifelse team != nobody [
        create-link-with tm [ set color yellow ]
        setxy (x + 1 * (sin random 360)) (y + 1 * (cos random 360))

        let task# [who] of self
        ask tm [
          set task-id task#
          set tasks-dw [tasks-dw] of self + 1
        ]
        ;; SELECT TEAM FOR THIS TEAM MANAGER AND ASSIGN LINK EACHOTHER
        ask team [
          let id [who] of self
          create-links-with team with [who != id] [ set color orange ]
          set team? false
        ]
        set t-s 1 ;; SET STATUS AS ACTIVE ONCE THE TASK IS ASSIGNED TO THE TEAM
        ;; REQUIRED CALCULATIONS OF ATTRIBUTES
        set p2 (team-experience team [difficulty] of self)
      ]
      [
        ask self [die]
        set loop? false
      ]
    ]
    set #tasks #tasks - 1
  ]
end

;; FUNCTION FOR CREATING AND ASSIGNING OF TASKS TO INDIVIDUAL
to create-assign-ind-tasks
  let #tasks count employees with [role = 0 and task-id = -1]
  while [#tasks != 0] [
    let empl one-of employees with [role = 0 and task-id = -1]
    ;; ASSIGN TASK TO THE ONE OF EMPLOYEES AVAILABLE
    ;; SET POSITION OF THE TASK NEAR THE EMPLOYEE
    ask (setup-task false) [
      setxy ([xcor] of empl + 1 * (sin random 360)) ([ycor] of empl + 1 * (cos random 360))
      create-link-with empl [set color yellow]
      ;; ASSIGN TASK ID TO EMPLOYEE
      let task# [who] of self
      ask empl [
        set task-id task#
        set team? false
        set tasks-dw [tasks-dw] of self + 1
      ]
      set t-s 1 ;; SET STATUS AS ACTIVE ONCE THE TASK IS ASSIGNED TO THE EMPLOYEE
      ;; REQUIRED CALCULATIONS OF ATTRIBUTES
      set p2 (individual-experience empl [difficulty] of self)
    ]
    set #tasks #tasks - 1
  ]
end

;; CALCULATION OF EPERIENCE OF A TEAM
to-report team-experience [team t-d]
  let tdi (task-d-ind t-d)
  let _e 0
  ask team [
    ifelse tdi = 1 [set _e _e + ([e1] of self)]
    [
      ifelse tdi = 2 [set _e _e + ([e2] of self)]
      [set _e _e + ([e3] of self)]
    ]
  ]
  report _e / count team
end

;; CALCULATION OF EPERIENCE OF AN EMPLOYEE
to-report individual-experience [empl t-d]
  let tdi (task-d-ind t-d)
  ifelse tdi = 1 [report [e1] of empl]
  [
    ifelse tdi = 2 [report [e2] of empl]
    [report [e3] of empl]
  ]
end

;; REPORTER FOR TASK DIFFICULTY INDEX
to-report task-d-ind [t-d]
  if t-d >= 1 and t-d <= 33 [report 1]
  if t-d >= 34 and t-d <= 66 [report 2]
  if t-d >= 67 [report 3]
end

;; FUNCTION TO ALLOCATE APPROPRIATE RESOURCES
to allocate-resources
  ask tasks with [t-s = 1 and count my-links with [color = green] = 0] [ ;; ACTIVE TASKS WITH NO ATTACHED RESOURCES
    let rdi resource-dim-ind (count my-links with [color = yellow])
    let resr resources with [count my-links with [color = green] = 0 and dimension = rdi]
    if one-of resr != nobody [
      let x [xcor] of self
      let y [ycor] of self
      create-link-with one-of resr [
        set color green
        ask end1 [ setxy (x + 1 * (sin random 360)) (y + 1 * (cos random 360)) ]
      ]
      ;; UPDATING AVERAGE RESOURCE DELAY FOR AN EMPLOYEE
      let tl [t-l] of self
      ask (turtle-set [other-end] of my-links with [color = yelLow]) with [color = yellow] [
        set avg-resources-delay ((avg-resources-delay * (tasks-dw - 1)) + tl) / tasks-dw
      ]
    ]
  ]
end

;; REPORTER FOR REQUIRED RESOURCE DIMENSION INDEX
to-report resource-dim-ind [team-size]
  ifelse team-size = 1 [report 1] ;; INDIVIDUAL
  [
    ifelse (team-size - 1) < avg-team-size [report 2] ;; SMALL TEAM SIZE
    [report 3] ;; LARGE TEAM SIZE
  ]
end

;; FUNCTION FOR UPDATION OF TASKS
to update-tasks
  ask tasks with [count my-links with [color = yellow] > 0] [
    set t-l t-l + 1
    set task-wl [difficulty] of self * (exp (alpha * [t-l] of self))
    if count my-links with [color = green] > 0 [
      let _task self
      let t-c [team-c] of self
      let t-d [difficulty] of self
      ask turtle-set [other-end] of my-links with [color = yellow] [
        set w-c (tendency self _task) * [ability] of self ;; CALCULATION OF INDIVIDUAL WORK CONTRIBUTION
        set t-c [team-c] of _task + [w-c] of self
      ]
      set team-c t-c
      set p3 team-c / task-wl ;; PROBABILITY P3
                              ;; CHECK THE COMPLETION STATUS OF THE TASK
      if [team-c] of self >= [task-wl] of self [ task-completion self t-d ]
    ]
  ]
end

;; REPORTER FOR CALCULATION OF TENDENCY OF AN EMPLOYEE TOWARDS A TASK
to-report tendency [emp _task]
  let i-ach 1 - (([p1] of _task + [p2] of _task + [p3] of _task) / 3)
  let i-aff 1 - [p1] of _task
  let i-pow 1 - [p1] of _task

  ;; ACHIEVEMENT COMPONENT OF TENDENCY
  let t1 (1 / 3.249629) * (( [s1] of emp / (1 + exp (20 * (0.25 - (1 - i-ach)))) ) - ( [s1] of emp / (1 + exp (20 * (0.75 - (1 - i-ach)))) ))
  ;; AFFILIATION COMPONENT OF TENDENCY
  let t2 (1 / 3.249629) * (( [s2] of emp / (1 + exp (20 * (i-aff - 0.3))) ) - ( [s2] of emp / (1 + exp (20 * (i-aff - 0.1))) ))
  ;; POWER COMPONENT OF TENDENCY
  let t3 (1 / 3.249629) * (( [s3] of emp / (1 + exp (20 * (0.6 - i-pow))) ) - ( [s3] of emp / (1 + exp (20 * (0.9 - i-pow))) ))

  ;; PLOT TENDENCY AND IT'S INNER ATTRIBUTES
  set-current-plot "tendency-plot"
  set-current-plot-pen "achievement"
  plot (t1)
  set-current-plot-pen "affiliation"
  plot (t2)
  set-current-plot-pen "power"
  plot (t3)
  set-current-plot-pen "tendency"
  plot (t1 + t2 + t3)

  report (t1 + t2 + t3)
end

;; FUNCTION TO RUN AFTER A TASK COMPLETION
to task-completion [_task t-d]
  ask _task [
    let tl [t-l] of self
    let sum-comp (sum [knowledge] of turtle-set [other-end] of my-links with [color = yellow])
    let team-count count turtle-set [other-end] of my-links with [color = yellow]
    let td [difficulty] of self
    let tc [team-c] of self
    ;; UPDATE ASSIGNED EMPLOYEES EXPERIENCE AND THEN UNASSIGN THEM FROM THE TASK
    ask turtle-set [other-end] of my-links with [color = yellow] [
      set tasks-solved [tasks-solved] of self + 1
      set avg-task-life ((avg-task-life * ([tasks-solved] of self - 1)) + tl) / [tasks-solved] of self
      ifelse (task-d-ind t-d) = 1 [ set e1 1 ]
      [
        ifelse (task-d-ind t-d) = 2 [ set e2 1 ]
        [ set e3 1 ]
      ]
      set task-id -1
      ;; CALCULATING COMPETENCE INCREASE FOR EACH EMPLOYEE BASED ON COMPETENCES OF OTHER TEAM MEMBERS
      ;; AFTER COMPLETION OF EVERY TASK EACH EMPLOYEE WILL GAIN 10% OF AVERAGE COMPETENCE OF THE TEAM
      if any? my-links with [color = orange] and td > ([ability] of self * 20) [
        set knowledge ( (knowledge * ([tasks-solved] of self - 1) + ( knowledge + ((sum-comp - [knowledge] of self) / (team-count - 1)) ) ) / [tasks-solved] of self )
        ;; set knowledge knowledge + ( (sum-comp - [knowledge] of self) / (team-count - 1) ) * (10 / 100)
        ;; set knowledge knowledge + 0.02
        set commitment ( (commitment * ([tasks-solved] of self - 1)) + ([w-c] of self / tc) ) / [tasks-solved] of self ;; CALCULATING AVERAGE OF OVERALL WORK CONTRIBUTION OF AN EMPLOYEE
      ]
      ;; CALCULATING COMPETENCE FOR THE TEAM MANAGER
      ;; INCREASE OF COMPETENCE OF TEAM MANAGER WILL BE 6.25% OF TEAM MEMBER'S
      if role = 1 [
        set knowledge (knowledge * ([#teams-formed] of self - 1) + ( knowledge + ((sum-comp - [knowledge] of self) / (team-count - 1)) * (1 / 100) )) / [#teams-formed] of self
        ;; set knowledge knowledge + ( (sum-comp - [knowledge] of self) / (team-count - 1) ) * (5 / 100)
      ]
      ;; REMOVE ALL LINKS AND MOVE THE EMPLOYEE
      ask my-links with [color = orange or color = white] [die]
      if [role] of self = 0 [ setxy random-xcor random-ycor ] ;; MOVE EMPLOYEES TO RANDOM POSITIONS AFTER TASK COMPLETION (NOT TEAM MANAGER)
      set team? true
      calc-emp-performance self
    ]
    ask my-links [die]
    set t-s 2
    die
  ]
end

;; REPORTS AVERAGE VALUE OF THE COMPETENCES OF A TEAM
to-report avg-team-comp [team]
  report (sum [knowledge] of team) / count team
end

;; FUNCTION FOR UPDATING DAYS OF WORK OF AN EMPLOYEE
to update#days-worked
  ask employees with [role = 0] [ set #days-worked [#days-worked] of self + 1 ]
end

;; FUNCTION FOR CALCULATING OPPORTUNITY VARIABLE OF ALL EMPLOYEES
to calc-opportunity
  let atf avg#teams-formed ;; AVERAGE # TEAMS FORMED
  let adw avg#days-worked  ;; AVERAGE # DAYS WORKED
  ask employees with [role = 0] [
    set opportunity #teams-formed / ((#days-worked / adw) * atf) ;; #TEAMS FORMED / ACTUAL #TEAMS COULD HAVE FORMED
  ]
end

;; REPORTS AVERAGE DAYS OF EMPLOYEES WORK
to-report avg#days-worked
  report (sum [#days-worked] of employees with [role = 0]) / count employees with [role = 0]
end

;; REPORTER FOR ACTUAL NUMBER OF TEAMS AN EMPLOYEE COULD HAVE FORMED OVERTIME
to-report avg#teams-formed
  report (sum ([#teams-formed] of employees with [role = 0])) / count employees with [role = 0]
end

;; CALCULATING INDIVIDUAL PERFORMANCE
;; THE FORMULA CONSIDERED FROM (https://www.opm.gov/policy-data-oversight/performance-management/performance-management-cycle/developing/formula-for-maximizing-performance/)
to calc-emp-performance [empl]
  ;; FORMULA FOR CALCULATING PERFORMANCE OF AN EMPLOYEE
  ;; --capcity--
  ;; performance = capacity * commitment (capcity = comptencies * resources * opportunity)
  ;; COMPETENCE AND BEHAVIOUR ARE CONSIDERED TO CALCULATE COMPETENCIES
  ;; AVEREAGE RESOURCES DELAY IS USED TO CALCULATE THE RESOURCES VALUE (MORE DELAY LESS VALUE)
  ;; OPPORTUNITY IS CALCULATED ALREADY AT EACH TIME STEP
  ;; --commitment--
  ;; WROK CONTRIBUTION OF EACH EMPLOYEE AT EACH TIME STEP WHEN ATTACHED TO A TASK
  let mc (sum [knowledge] of employees) / count employees
  ;; TERMS USED FOR PLOTTING CAPACITY, COMMITMENT AND PERFORMANCE
  ;; let avg-cap 0
  ;; let avg-comt 0
  ask empl [
    let competencies [knowledge] of self                                                  ;; TERMS USED FOR CALCULATING
    let _resources 1 - ( ([avg-resources-delay] of self / [avg-task-life] of self) / 10 )      ;; CAPACITY OF AN EMPLOYEE
    set performance ( (competencies * _resources * [opportunity] of self) * [commitment] of self )
    ;; CALCULATING TERMS FOR PLOTTING PURPOSE
    ;; set avg-cap avg-cap + (competencies * _resources * [opportunity] of self)
    ;; set avg-comt avg-comt + [commitment] of self
  ]
  ;; PLOT AVERAGE CAPACITY
  ;;set-current-plot-pen "avg-cap"
  ;;plot(avg-cap / (count employees))
  ;; PLOT AVERAGE OF COMMITMENT
  ;;set-current-plot-pen "avg-comt"
  ;;plot(avg-comt / (count employees))
end

;; FINDING ANY EMPLOYEE CAN BE TEAM MANAGER
to emp-to-tm
  if ticks mod (365 * 3) = 0 [ set check-prom true ]
  if check-prom and promote-emp = nobody [
    ;; UPDATES tm-prom-days VARIABLE AT EACH TIME STEP
    update-tmpd-var
    ;; PROMOTE EMPLOYEE WITH MAX COMMITMENT
    set-promote-emp
  ]
end

;; FUNCTION FOR UPDATING tm-prom-days VARIABLE
to update-tmpd-var
  ask employees with [role = 0] [
    ifelse knowledge >= ((sum [knowledge] of employees with [role = 1]) / count employees with [role = 1]) [
      set tm-prom-days tm-prom-days + 1
    ][ set tm-prom-days 0 ]
  ]
end

;; FUNCTION FOR PROMOTING AN EMPLOYEE WITH MAX COMMITMENT AMONG ALL
to set-promote-emp
  if any? employees with [role = 0 and tm-prom-days > 14] [
    set promote-emp max-one-of (employees with [role = 0 and tm-prom-days > 14]) [commitment]
    set check-prom false
  ]
end

;; FUNCTION FOR PROMOTING EMPLOYEE ONCE FREE
to promote-when-free
  if promote-emp != nobody[
    ask promote-emp [
      if count my-links = 0 [
        set role 1
        set color white
        set s1 2.0
        set s2 2.0
        set s3 2.0
        ifelse random-float 1 < psi3 [ set ability 3 ]
        [
          ifelse random-float 1 < psi4 [ set ability 4 ]
          [ set ability 5 ]
        ]
        ;; UPDATING POSITIONS OF TEAM MANAGERS IN SIMULATION
        ;; position-tm
        set promote-emp nobody
        ;; HIRE NEW EMPLOYEES
        hire-employees ( (avg-team-size / 2) + max (list 0 ((count employees with [role = 1] * avg-team-size) - count employees with [role = 0])) )
      ]
    ]
  ]
end

;; FUNCTION FOR POSITIONING AND UPDATING ALL TEAM MANAGERS IN THE ENVIRONMENT
to position-tm
  ;; SETTING UP TEAM MANAGERS POSITIONS
  let t-x ceiling (count employees with [role = 1] / 4)
  let x ceiling (2 * max-pxcor) / (t-x + 1)
  let y ceiling (2 * max-pycor) / 5
  let i 1 ;; for itertion purpose
  ask employees with [role = 1] [
    setxy (x * i) - max-pxcor y - max-pycor
    if i mod t-x = 0 [
      set i 0
      set y y + (2 * max-pycor) / 5
    ]
    set i i + 1
  ]
end

;; FUNCTION FOR HIRING NEW EMPLOYEES
to hire-employees [emp-count]
  ask one-of employees with [role = 0] [
    let knowl-emp mean [knowledge] of employees
    hatch avg-team-size [
      setxy random-xcor random-ycor
      set knowledge random-normal knowl-emp knowledge-std
      set #days-worked 0
      set avg-resources-delay 0
      set avg-task-life 0
      set resign-prob 0
      set fire-prob 0
      set commitment random-normal 2.729932 0.711561
      set performance 0
      set team? true
      set tasks-dw 0
      set tasks-solved 0
      set task-id -1
      set #teams-formed 0
      ;; MOTIVE PROFILE DISTRIBUTION
      ifelse random-float 1 < gamma1 [ set s1 2.0 ] [ set s1 1.0 ]
      ifelse random-float 1 < gamma2 [ set s2 2.0 ] [ set s2 1.0 ]
      ifelse random-float 1 < gamma3 [ set s3 2.0 ] [ set s3 1.0 ]
      ;; ABILITY
      ifelse random-float 1 < psi1 [ set ability 1 ]
      [
        ifelse random-float 1 < psi2 [ set ability 2 ]
        [
          ifelse random-float 1 < psi3 [ set ability 3 ]
          [
            ifelse random-float 1 < psi4 [ set ability 4 ]
            [ set ability 5 ]
          ]
        ]
      ]
      ;; EXPERIENCE VARIABLES (EASY, MEDIUM, HARD) TASKS
      set e1 0
      set e2 0
      set e3 0
      ;; NUMBER OF CONSECUTIVE DAYS AN EMPLOYEE CAN BE TEAM MANAGER
      set tm-prom-days 0
    ]
  ]
  gen-new-resources
end

;; GENERATE NEW RESOURCES
to gen-new-resources
  ;; GENERATE REQUIRED NEW RESOURCES OF DIMENSION 2
  let rc ( (count employees with [role = 1] / 2) - ceiling (count employees with [role = 1] / avg-team-size) ) - (count resources with [dimension = 2])
  ask one-of resources with [dimension = 2] [
    hatch rc [ setxy random-xcor random-ycor ]
  ]
  ;; GENERATE REQUIRED NEW RESOURCES OF DIMENSION 3
  set rc ( (count employees with [role = 1]) - count resources with [dimension = 2] ) - (count resources with [dimension = 3])
  ask one-of resources with [dimension = 3] [
    hatch rc [ setxy random-xcor random-ycor ]
  ]
  ;; GENERATE REQUIRED NEW RESOURCES OF DIMENSION 1
  ;;set rc ( (count employees with [role = 0]) - (count employees with [role = 1] * avg-team-size) ) - (count resources with [dimension = 1])
  ;;ask one-of resources with [dimension = 1] [
  ;;  hatch rc [ setxy random-xcor random-ycor ]
  ;;]
end

;; FUNCTION FOR DISPLAYING ALL PLOTS
to plots
  ;; PLOT EMPLOYEES COUNT
  set-current-plot "#employees"
  set-current-plot-pen "count"
  plot count employees with [role = 0]
  ;;
  let empls employees with [role = 0 and #days-worked > perf-calc-days]
  if count employees with [role = 0 and #days-worked > perf-calc-days] > 0 [
    ;; PLOT AVERAGE TASKS SOLVED
    if ticks mod 30 = 0 [
      set-current-plot "average#tasks-solved"
      set-current-plot-pen "avg-tasks-solved-count"
      plot (sum [tasks-solved] of empls) / (count empls)
    ]
    ;; PLOT AVERAGE OF TOTAT OF AVERAGE OF RESOURCES DELAY OF EACH EMPLOYEE
    set-current-plot "avg-avg-resource-delay"
    set-current-plot-pen "avg-avg-resource-delay"
    plot((sum [avg-resources-delay] of empls) / count empls)
    ;; PLOT AVERAGE OF TOTAT OF AVERAGE OF RESOURCES DELAY OF EACH EMPLOYEE
    set-current-plot "avg-avg-task-life"
    set-current-plot-pen "avg-avg-task-life"
    plot((sum [avg-task-life] of empls) / count empls)
    ;; PLOT AVERAGE OF PERFORMANCE CALCULATED FOR ALL EMPLOYEES
    if ticks mod 365 = 0 [
      set-current-plot "avg-performance"
      set-current-plot-pen "avg-perf"
      plot( mean [performance] of empls )
    ]
  ]
end


;; POINTS TO BE NOTED FOR FURTHUR WORK
;; COMPETENCE OF NEWLY HIRED EMPLOYE SHOULD BE COMPUTED WITH MEAN AS (MEAN OF COMPETENCE OF ALL EMPLOYEES AT THE MOMENT) (TO MEET THE COMPANY LEVEL)
@#$#@#$#@
GRAPHICS-WINDOW
772
10
1209
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
16
11
188
44
#employees
#employees
0
500
20.0
1
1
NIL
HORIZONTAL

SLIDER
15
55
187
88
#team-managers
#team-managers
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
15
94
187
127
knowledge_mean
knowledge_mean
0
3
3.0
0.1
1
NIL
HORIZONTAL

BUTTON
682
10
745
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
672
55
758
88
GO(once)
go
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
0

BUTTON
685
95
748
128
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
0

SLIDER
205
12
377
45
min-team-size
min-team-size
0
10
4.0
1
1
NIL
HORIZONTAL

PLOT
564
150
764
300
#employees
ticks
# employees
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"count" 1.0 0 -16777216 true "" ""

PLOT
242
267
557
451
tendency-plot
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"tendency" 1.0 0 -16777216 true "" ""
"achievement" 1.0 0 -11085214 true "" ""
"affiliation" 1.0 0 -13345367 true "" ""
"power" 1.0 0 -2674135 true "" ""

MONITOR
564
457
691
498
Average # tasks dealt
(sum [tasks-dw] of employees with [role = 0]) / (count employees with [role = 0])
5
1
10

MONITOR
696
457
830
498
Average # tasks solved
(sum [tasks-solved] of employees with [role = 0]) / (count employees with [role = 0])
5
1
10

MONITOR
564
547
718
588
Average team size overtime
avg-team-size
5
1
10

MONITOR
564
498
707
539
Total # tasks dealt with
sum [tasks-dw] of employees with [role = 0]
17
1
10

MONITOR
712
498
828
539
Total # tasks solved
sum [tasks-solved] of employees with [role = 0]
5
1
10

MONITOR
842
457
996
498
Total # resources currently
count resources
5
1
10

MONITOR
842
500
992
541
Total # resources attached
count resources with [count my-links > 0]
5
1
10

MONITOR
365
457
560
498
Total # tasks dealing with currently
count tasks with [count my-links with [color = yellow] > 0]
5
1
10

MONITOR
1006
456
1134
497
Average opportunity
(sum [opportunity] of employees with [role = 0]) / count employees with [role = 0]
5
1
10

MONITOR
842
541
954
582
#ind-resources idle
count resources with [count my-links = 0 and dimension = 1]
0
1
10

PLOT
564
301
764
451
average#tasks-solved
ticks
avg-tasks-solved
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"avg-tasks-solved-count" 1.0 0 -2674135 true "" ""

PLOT
1213
297
1413
447
avg-avg-resource-delay
ticks
avg-avg-resource-delay
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"avg-avg-resource-delay" 1.0 0 -14439633 true "" ""

MONITOR
1213
446
1356
487
avg-avg-resources-delay
(sum [avg-resources-delay] of employees with [role = 0]) / count employees with [role = 0]
5
1
10

MONITOR
1212
106
1313
147
avg-avg-task-life
(sum [avg-task-life] of employees with [role = 0]) / count employees with [role = 0]
5
1
10

PLOT
1212
145
1412
295
avg-avg-task-life
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"avg-avg-task-life" 1.0 0 -13345367 true "" ""

MONITOR
952
541
1072
582
#team-resources idle
count resources with [count my-links = 0 and dimension != 1]
5
1
10

MONITOR
564
587
666
628
avg no team time
avg-no-team-time
5
1
10

MONITOR
242
457
348
498
mean competence
(sum [knowledge] of employees with [role = 0]) / count employees with [role = 0]
5
1
10

PLOT
195
55
557
265
avg-performance
ticks
avg-performace
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"avg-perf" 1.0 0 -12895429 true "" ""
"avg-cap" 1.0 0 -7500403 true "" ""
"avg-comt" 1.0 0 -2674135 true "" ""

SLIDER
15
126
187
159
knowledge-std
knowledge-std
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
385
22
557
55
performance-const
performance-const
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
15
162
187
195
perf-calc-days
perf-calc-days
0
30
30.0
1
1
days
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
