globals [
  num-muertes
  num-camas-usadas
  proxima-llegada

  %-leve
  %-grave
  %-muy-grave

  doctores-desocupados
  camas-desocupadas
  salas-desocupadas

  lista-leves
  lista-graves
  lista-muy-graves

  prom-tiempo-reposo

  ;;Constantes de estados
  estado-llegada ;; Estado del paciente cuando llega al hospital
  estado-espera-enfermera ;; Estado del paciente cuando esta en una silla a la espera de ser atendido por una enfermera
  estado-verificando-condicion ;; Estado del paciente cuando se encuestran con la enfermera verificando la condicion de salud
  estado-espera-atencion ;; Estado del paciente cuando espera a ser atendido por el doctor
  estado-en-quirofano ;; Estado del paciente cuando se encuentra en un quirofano
  estado-esperando-cama ;; Estado del paciente que esta esperado un cama
  estado-listo-para-salir ;; Estado del paciente cuando se encuentra listo para salir
  estado-ocupado ;; Estado de las tortugas que se encuentran ocupadas
  estado-libre ;; Estado de las tortugas que se encuentran desocupadas
]

turtles-own [
  tipo ;; Tipo de paciente
  categoria ;; Categoria del paciente 1 (leve), 2 (grave), 3 (muy grave)
  estado ;; Estado del paciente en dado momento
  tiempo-de-vida ;; Tiempo de vida del paciente
  tiempo-condicion ;; Tiempo que se dura en determinar la condicion del paciente
  tiempo-atencion ;; Tiempo que se va a durar ateniendo al paciente
  n-paciente ;; paciente que esta relacionado con el agente, 0 si no hay ningun paciente relacionado
]

;; Inicializa el ambiente para su ejecucion
to setup
  clear-all
  setup-estados
  setup-turtles
  setup-recursos
  setup-porcentajes
  setup-listas
  set proxima-llegada (random-poisson pacientes-minuto)
  reset-ticks
end

;; Hace las iteraciones en cada tik
to go
  if ticks >= (proxima-llegada) [
    crear-paciente
    set proxima-llegada ((random-poisson pacientes-minuto) + ticks)
  ]
  acomodar-pacientes
  verificar-pacientes
  verificar-condicion
  atender-paciente
  verificar-fin-atencion
  acomodar-pacientes-reposo
  verificar-muertes
  tick
end

;; ------------------------------------------------Setups------------------------------------------------------------------------------
;; Establece la configuracion de las tortugas
to setup-turtles
  setup-doctores
  setup-enfermeras
end

to setup-recursos
  set doctores-desocupados cant-doctores
  set camas-desocupadas cant-camas
  set salas-desocupadas cant-salas
end


;; Establece la configuracion para las tortugas doctores
;; Los ubica en la parte superior izquierda
to setup-doctores
  create-turtles cant-doctores [
    set color white
    set tipo "doctor"
    set xcor min-pxcor + 1 + random 15
    set ycor max-pycor - 1 - random 3
    set shape "person"
    set estado estado-libre
    set n-paciente 0
  ]
end

;; Establece la configuracion para las tortugas enfermeras
;; Las ubica en la parte superior derecha
to setup-enfermeras
  create-turtles cant-enfermeras [
    set color blue
    set tipo "enfermera"
    set xcor max-pxcor - 2 - random 13
    set ycor max-pycor - 3 - random 4
    set shape "person"
    set estado estado-libre
    set n-paciente 0
  ]
end

;; Establece los porcentajes o rangos para las probabilidades puestas en la interfaz
to setup-porcentajes
  set %-leve (%-pacientes-leves - 1)
  set %-grave (%-pacientes-leves + %-pacientes-graves - 1)
  set %-muy-grave (%-pacientes-leves + %-pacientes-graves + %-pacientes-muy-graves - 1)
end

;; Inicializa las listas de pacientes
to setup-listas
  set lista-leves []
  set lista-graves []
  set lista-muy-graves []
end

to setup-estados
  set estado-llegada 1 ;; Estado del paciente cuando llega al hospital
  set estado-espera-enfermera 2 ;; Estado del paciente cuando esta en una silla a la espera de ser atendido por una enfermera
  set estado-verificando-condicion 3 ;; Estado del paciente cuando se encuestran con la enfermera verificando la condicion de salud
  set estado-espera-atencion 4 ;; Estado del paciente cuando espera a ser atendido por el doctor
  set estado-en-quirofano 5 ;; Estado del paciente cuando se encuentra en un quirofano
  set estado-esperando-cama 6 ;; Estado del paciente que esta esperado un cama
  set estado-listo-para-salir 7 ;; Estado del paciente cuando se encuentra listo para salir
  set estado-ocupado 0 ;; Estado de las tortugas que se encuentran ocupadas
  set estado-libre 1 ;; Estado de las tortugas que se encuentran desocupadas
end

;; ------------------------------------------------Funciones------------------------------------------------------------------------------

;; Crea un paciente
to crear-paciente
  create-turtles 1 [
    set color 136
    set tipo "paciente"
    set xcor max-pxcor - 1
    set ycor min-pycor + 1
    set shape "person"
    set tiempo-de-vida 0
    set estado estado-llegada
  ]
end

;; Metodo para acomodar los pacientes en las sillas
to acomodar-pacientes
  let pacientes sort turtles with [ tipo = "paciente" and estado = estado-llegada ] ;; Lista de pacientes buscando una silla

  while [(length pacientes > 0)][

    let paciente (first pacientes) ;; Se obtiene primer paciente de la lista

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      ;; Se mueve el paciente a la silla
      set xcor ((max-pxcor - 2) - random 12 )
      set ycor ((min-pycor + 2) + random 23 )
      ;;
      set estado estado-espera-enfermera ;; El estado del paciente cambia a espera-enfermera
    ]

    set pacientes remove-item 0 pacientes ;; Se elimina el paciente de la lista
  ]
end

;; Metodo para que las enfermeras atiendan a los pacientes
to verificar-pacientes
  let enfermeras sort turtles with [ tipo = "enfermera" and estado = estado-libre ] ;; Lista de enfermeras disponibles
  let pacientes sort turtles with [ tipo = "paciente" and estado = estado-espera-enfermera ] ;; Lista de pacientes esperando por una enfermera

  while [(length pacientes > 0) and (length enfermeras > 0)][

    let paciente (first pacientes) ;; Se obtiene primer paciente de la lista
    let enfermera (first enfermeras) ;; Se obtiene primer enfermera de la lista

    ;; Se modifica la enfermera
    ask turtle ([who] of enfermera) [
      move-to paciente ;; Se mueve la enfermera a la posicion del paciente
      set xcor (xcor - 1) ;; Se mueve la enfermera al costado izq del paciente
      set estado estado-ocupado ;; El estado de la enfermera pasa a ocupado
      set n-paciente paciente ;; Se asocia el paciente a la enfermera
    ]

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      set tiempo-condicion ((random-exponential prom-deteccion-condicion) + ticks) ;; Se establece el tiempo que durará la verificacion de la condicion
      set estado estado-verificando-condicion ;; El estado del paciente cambia a verificando-condicion
    ]

    set pacientes remove-item 0 pacientes ;; Se elimina el paciente de la lista
    set enfermeras remove-item 0 enfermeras ;; Se elimina la enfermera de la lista
  ]
end

;; Metodo para verificar la condicion del paciente
to verificar-condicion
  let pacientes sort turtles with [ tipo = "paciente" and estado = estado-verificando-condicion and tiempo-condicion <= ticks] ;; Lista de pacientes listos para saber su condicion

  while [length pacientes > 0][

    let paciente (first pacientes) ;; Se obtiene primer paciente de la lista

    let proba random 100 ;; Numero aleatorio que indicara la condicion
    let colorP 0 ;; variable para el nuevo color del paciente
    let condicion 0 ;; variable para la nueva condicion del paciente
    let tiempoVida 0 ;; variable para el tiempo de vida que le queda al paciente

    (ifelse
      proba <= %-leve [
        set condicion 1 ;; Nueva condicion es leve
        set colorP green ;; Nuevo color es verde
        set tiempoVida (ticks + (random-poisson prom-espera-leve)) ;; Tiempo de vida
      ]
      proba <= %-grave [
        set condicion 2 ;; Nueva condicion es grave
        set colorP yellow ;; Nuevo color es amarillo
        set tiempoVida (ticks + (random-poisson prom-espera-grave)) ;; Tiempo de vida
      ]
      proba <= %-muy-grave [
        set condicion 3 ;; Nueva condicion es muy-grave
        set colorP red ;; Nuevo color es rojo
        set tiempoVida (ticks + (random-poisson prom-espera-muy-grave)) ;; Tiempo de vida
    ])

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      set categoria condicion ;; Se le cambia la categoria segun la condicion
      set color colorP ;; Se le cambia el color segun la condicion
      set tiempo-de-vida tiempoVida ;; Se le establece el tiempo de vida segun la condicion
      set estado estado-espera-atencion ;; El estado del paciente cambia a espera-atencion
    ]

    ask turtles with [tipo = "enfermera" and n-paciente = paciente] [
      ;; Se mueve la enfermera a un puesto inicial
      set xcor max-pxcor - 2 - random 13
      set ycor max-pycor - 3 - random 4
      ;;
      set estado estado-libre ;; La enfermera pasa a estar libre
    ]

    set pacientes remove-item 0 pacientes ;; Se elimina el paciente de la lista
  ]
end

;; Metodo para atender a un paciente
to atender-paciente
  let pacientes sort-by [[t1 t2] -> [categoria] of t1 > [categoria] of t2] turtles with [ tipo = "paciente" and estado = estado-espera-atencion ] ;; Lista de pacientes esperando un doctor ordenada por condicion del paciente

  if length pacientes > 0 [

    let paciente (first pacientes) ;; Se obtiene primer paciente de la lista

     (ifelse ;; Se procesa el paciente segun la categoría
      ([categoria] of paciente) = 1 [ ;; Categoría leve
        atender-leve paciente
      ]
      ([categoria] of paciente) = 2 [ ;; Categoría grave
        atender-grave paciente
      ]
      ([categoria] of paciente) = 3 [ ;; Categoría muy-grave
        atender-muy-grave paciente
      ])
  ]
end

;; Metodo para atender un paciente leve
to atender-leve [paciente]
  if doctores-desocupados >= 1 [ ;; Se verifica disponibilidad de doctores

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      set tiempo-atencion ((random-poisson prom-atencion-leve) + ticks) ;; Se le establece el tiempo de atencion
      set estado estado-en-quirofano ;; El estado del paciente cambia a en-quirofano
    ]

    ;; Se modifica el doctor
    ask one-of turtles with [tipo = "doctor" and estado = estado-libre ] [
      move-to paciente ;; Se mueve el doctor a la posicion del paciente
      set xcor xcor - 1 ;; Se mueve el doctor al costado del paciente
      set estado estado-ocupado ;; El doctor pasa a estar ocupado
      set n-paciente paciente ;; Se asocia el paciente al doctor
    ]

    set doctores-desocupados (doctores-desocupados - 1) ;; Se disminuye cantidad de doctores libres
  ]
end

to atender-grave [paciente]

  if ((doctores-desocupados >= 3) and (salas-desocupadas > 0)) [  ;; Se verifica disponibilidad de doctores y quirofanos

    ;; Se ocupa el quirofano
    set salas-desocupadas (salas-desocupadas - 1)

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      ;; Se mueve el paciente al quirofano
      set xcor ((min-pxcor + 2) + random 13 )
      set ycor ((max-pycor - 5) - random 10 )
      ;;
      set tiempo-atencion ((random-poisson prom-atencion-grave) + ticks)  ;; Se le establece el tiempo de atencion
      set estado estado-en-quirofano ;; El estado del paciente cambia a en-quirofano
    ]

    ;; Se modifican los doctores
    ask n-of 3 turtles with [tipo = "doctor" and estado = estado-libre ] [
      ;; Se colocan los doctores rodeando al paciente
      move-to paciente
      set xcor xcor - 1
      set ycor ycor - 1
      set xcor xcor + random 3
      set ycor ycor + random 3
      ;;
      set estado estado-ocupado ;; Los doctores pasan a estar ocupados
      set n-paciente paciente ;; Se asocia el paciente a los doctores
    ]

    set doctores-desocupados (doctores-desocupados - 3) ;; Se disminuye cantidad de doctores libres
  ]
end

to atender-muy-grave [paciente]
  if ((doctores-desocupados >= 5) and (salas-desocupadas > 0)) [  ;; Se verifica disponibilidad de doctores y quirofanos

    ;; Se ocupa el quirofano
    set salas-desocupadas (salas-desocupadas - 1)

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      ;; Se mueve el paciente al quirofano
      set xcor ((min-pxcor + 2) + random 13 )
      set ycor ((max-pycor - 5) - random 10 )
      ;;
      set tiempo-atencion ((random-poisson prom-atencion-muy-grave) + ticks) ;; Se le establece el tiempo de atencion
      set estado estado-en-quirofano ;; El estado del paciente cambia a en-quirofano
    ]

    ;; Se modifican los doctores
    ask n-of 5 turtles with [tipo = "doctor" and estado = estado-libre ] [
      ;; Se colocan los doctores rodeando al paciente
      move-to paciente
      set xcor xcor - 1
      set ycor ycor - 1
      set xcor xcor + random 3
      set ycor ycor + random 3
      ;;
      set estado estado-ocupado ;; Los doctores pasan a estar ocupados
      set n-paciente paciente ;; Se asocia el paciente a los doctores
    ]

    set doctores-desocupados (doctores-desocupados - 5) ;; Se disminuye cantidad de doctores libres
  ]
end

;; Metodo para verificar los pacientes que terminan de ser atendidos
to verificar-fin-atencion
  let pacientes sort turtles with [ tipo = "paciente" and estado = estado-en-quirofano and tiempo-atencion <= ticks] ;; Lista de pacientes que terminan de ser atendidos

  while [length pacientes > 0][

    let paciente (first pacientes) ;; Se obtiene el primer paciente

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      set estado estado-esperando-cama ;; El paciente pasa a estar esperando cama
      if (categoria = 1)[ ;; Paciente con condicion leve
        set estado estado-listo-para-salir ;; Los pacientes leves pasan a estar listos-para-salir
        set doctores-desocupados (doctores-desocupados + 1) ;; Aumentamos cantidad de doctomer libres
      ]
      if (categoria = 2)[ ;; Paciente con condicion grave
        set doctores-desocupados (doctores-desocupados + 3) ;; Aumentamos cantidad de doctomer libres
      ]
      if (categoria = 3)[ ;; Paciente con condicion muy-grave
        set doctores-desocupados (doctores-desocupados + 5) ;; Aumentamos cantidad de doctomer libres
      ]
    ]

    ;; Se modifican los doctores
    ask turtles with [tipo = "doctor" and n-paciente = paciente] [
      ;; Se mueven los doctores a un puesto inicial
      set xcor min-pxcor + 1 + random 15
      set ycor max-pycor - 1 - random 3
      ;;
      set estado estado-libre ;; El estado de los doctores pasa a libre
      set n-paciente 0 ;; Se elimina la asociacion de los doctores con el paciente
    ]

    set pacientes remove-item 0 pacientes ;; Se elimina el paciente de la lista
  ]
end

to acomodar-pacientes-reposo
  let pacientes sort turtles with [ tipo = "paciente" and estado = estado-esperando-cama ] ;; Lista de pacientes esperando cama

  while [(length pacientes > 0) and (camas-desocupadas > 0)][

    let paciente (first pacientes) ;; Se obtiene el primer paciente

    ;; Se modifica el paciente
    ask turtle ([who] of paciente) [
      ;; Se mueve el paciente al area de camas
      set xcor ((min-pxcor + 2) + random 13 )
      set ycor ((min-pycor + 2) + random 13 )
      ;;
      set estado estado-listo-para-salir ;; El paciente pasa a estar listo-para-salir
    ]

    ;; Se ocupa la cama
    set camas-desocupadas (camas-desocupadas - 1)

    ;; Se libera el quirofano en el que estaba el paciente
    set salas-desocupadas (salas-desocupadas + 1)

    set pacientes remove-item 0 pacientes ;; Se elimina el paciente de la lista
  ]
end

;; Metodo para verificar los pacientes que mueren
to verificar-muertes
  let pacientes sort turtles with [ tipo = "paciente" and tiempo-de-vida != 0 and tiempo-de-vida < ticks ] ;; Lista de pacientes muertos

  while [length pacientes > 0] [

    let paciente (first pacientes) ;; Se obtiene el primer paciente

    (ifelse ;; Desocupar quirofanos o camas
      ((([estado] of paciente) = estado-en-quirofano) or (([estado] of paciente) = estado-esperando-cama))  [ ;; Desocupar quirofano

      ]
      ([estado] of paciente) = estado-listo-para-salir [ ;; Desocupar cama
        set camas-desocupadas (camas-desocupadas + 1)
      ])

    ;; Se liberan los doctores (si es necesario)
    ask turtles with [tipo = "doctor" and n-paciente = paciente] [
      ;; Se mueven los doctores a un puesto inicial
      set xcor min-pxcor + 1 + random 15
      set ycor max-pycor - 1 - random 3
      ;;
      set estado estado-libre ;; El estado de los doctores pasa a libre
      set n-paciente 0 ;; Se elimina la asociacion de los doctores con el paciente
    ]

    ;; Se liberan la enfermera (si es necesario)
    ask turtles with [tipo = "enfermera" and n-paciente = paciente] [
      ;; Se mueve la enfermera a un puesto inicial
      set xcor max-pxcor - 2 - random 13
      set ycor max-pycor - 3 - random 4
      ;;
      set estado estado-libre ;; El estado de la enfermera pasa a libre
      set n-paciente 0 ;; Se elimina la asociacion de la enfermera con el paciente
    ]

    ;; Se elimina el paciente
    ask turtle ([who] of paciente) [
      die ;; Se elimina la tortuga paciente
    ]

    set pacientes remove-item 0 pacientes ;; Se elimina el paciente de la lista
    set num-muertes (num-muertes + 1) ;; Se aumenta la cantidad de muertes
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
763
14
1264
516
-1
-1
14.94
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
1
1
1
ticks
30.0

SLIDER
21
175
200
208
cant-camas
cant-camas
0
49
22.0
1
1
NIL
HORIZONTAL

SLIDER
212
176
391
209
cant-salas
cant-salas
0
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
213
130
391
163
cant-enfermeras
cant-enfermeras
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
21
222
201
255
pacientes-minuto
pacientes-minuto
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
20
267
202
300
%-pacientes-leves
%-pacientes-leves
0
100
33.0
1
1
%
HORIZONTAL

SLIDER
20
360
204
393
%-pacientes-graves
%-pacientes-graves
0
100
33.0
1
1
%
HORIZONTAL

SLIDER
20
314
203
347
%-pacientes-muy-graves
%-pacientes-muy-graves
0
100
33.0
1
1
%
HORIZONTAL

BUTTON
68
41
152
85
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

SLIDER
21
129
200
162
cant-doctores
cant-doctores
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
20
415
204
460
NIL
num-muertes
17
1
11

MONITOR
213
415
398
460
NIL
num-camas-usadas
17
1
11

BUTTON
165
42
248
86
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
20
474
203
519
pacientes-leves-SA
count turtles with [categoria = 1]
17
1
11

MONITOR
212
474
396
519
pacientes-graves-SA
count turtles with [ categoria = 2]
17
1
11

MONITOR
406
474
590
519
pacientes-muy-graves-SA
count turtles with [ categoria = 3]
17
1
11

SLIDER
213
267
393
300
prom-espera-leve
prom-espera-leve
0
500
161.0
1
1
min
HORIZONTAL

SLIDER
213
313
394
346
prom-espera-grave
prom-espera-grave
0
500
139.0
1
1
min
HORIZONTAL

SLIDER
214
360
395
393
prom-espera-muy-grave
prom-espera-muy-grave
0
500
90.0
1
1
min
HORIZONTAL

SLIDER
404
268
583
301
prom-atencion-leve
prom-atencion-leve
0
100
5.0
1
1
min
HORIZONTAL

SLIDER
404
314
585
347
prom-atencion-grave
prom-atencion-grave
0
100
2.0
1
1
min
HORIZONTAL

SLIDER
405
359
585
392
prom-atencion-muy-grave
prom-atencion-muy-grave
0
100
5.0
1
1
min
HORIZONTAL

SLIDER
213
222
392
255
prom-deteccion-condicion
prom-deteccion-condicion
0
100
9.0
1
1
min
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

rectangle
false
0
Rectangle -7500403 true true 75 0 225 300

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
NetLogo 6.1.0
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
