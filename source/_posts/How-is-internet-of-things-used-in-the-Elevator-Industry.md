---
title: How is internet of things used in the Elevator Industry
date: 2017-03-10 14:29:00
categories: Elevator
tags: IOT, Elevator
toc: true
---
### Architecture diagram
![Diagram](http://oirr6l0ul.bkt.clouddn.com/network%20structure.png.png)

### Thinking spark
 
#### Data Center
 1. It is based on a database(postgresql) cluster based on the ubuntu server.
 2. In data center, it stores the information of every project: location, parametaers(elevator model, speed, load, etc.), running information, customer's info,bom tree of every unit, erp info, mes info, etc.
 3. According the unit running information, you can generate a leveling strategy  and rewrite to the unit controlling system to optimize the runnint efficiency.
 
#### Application Servers
 1. It is based on Ubuntu server.
 2. The erp system, mes system and restweb serve are deployed in it.

#### Gateway
1. It is a IOT gateway.(This is the key device of the internet of things)
2. Its operate system is openwrt.(2 core cpu, 128M Rom, 256M RAM)
3. Through it, running information of every unis is uploaded to database in data center. The optimized leveling strategy is writed into units controlling system.
4. The elevator's quantity, connecting to it, has a max value. So one project has more than one. 

#### Client
1. It may be a web-based client, or a mobile app in  phone.
2. Through it, customer can call one unit to level on the stop when customer want to go out from her/his location. But the priority of this calling command is less than it from the landing.


    
 