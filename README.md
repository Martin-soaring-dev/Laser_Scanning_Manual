# Extrusion 3D printer with integrated laser profile sensor - in NUS

## 1 简介（Introduction）

2D激光轮廓传感器(2D Laser profile sensor)集成到3D打印机中以实现3D扫描，如下所示。

该系统由传感器、运动控制平台(motion control platform)和气动挤压系统(pneumatic extrusion system)组成，通过以太网(Ethernet)或串口(Serial Port)与PC机连接。

打印Gcode由开源切片软件生成，并由开源用户界面(UI)软件读取和发送。

打印时，命令由PC通过串口发送到控制板，在控制板(control board)上解码并执行。

在matlab中编写了一套实现扫描功能的程序。

扫描时需要运动与传感器的协调，PC通过串口控制运动平台移动一步，再通过以太网与传感器通讯获取截面，如此循环直至扫描完成。

![image](images/Figure_01.jpg)
图1 系统框图

### 如何从0开始搭建整个系统呢？

1. 购买/制造相应的组件，并按照设计进行装配
2. 确定各个端子的对应情况，并完成接线
3. 完成PC的环境准备、打印系统和扫描系统的配置
   1. 电脑环境的准备
   2. 打印和挤出系统的配置
   3. 扫描系统的配置

## 2 结构（Structure）

本节将介绍系统内部的主要结构。

### (1) 运动控制平台（Motion Control Platform）
运动控制平台是一个三轴钻床的基础上改装的。

![image](images/Figure_02.png)

图2 运动平台（原始） 

定制了如下组件

![image](images/Figure_03.png)

图3 改造示意图 

#### 1）安装板
介绍：安装在Z轴滑板上的安装板，将注射器针筒和2D轮廓传感器安装在它上面。

![alt text](images/image.png)

制造：3D打印（FDM），工程塑料。

模型 3D Model：[click to get stl file](<3Dmodels/STL/安装板 - PlanB.STL>)

#### 2）底座组件

介绍：由基板、调节装置和底座构成。

![alt text](images/image-2.png)
![alt text](images/image-5.png)

制造：底座材料为不锈钢，通过激光切割和折弯制造。其余部件可直接采购。

模型 3D Model：[click to get stl file](<3Dmodels/STL/底座.STL>)

![alt text](images/96eef40f671b49c1fc0b6fbc2e41abf.jpg)

图4 运动平台（改造后）

装配体 Assembly：[click to get stl file](<3Dmodels\STP\Assembly - Carriage-Z.STEP>)

### (2) 挤出系统（Extrusion System）
挤出系统由气压分配器和挤出装置构成。气泵可根据实验室条件选购。
#### 1）气压分配器（Pressure Dispenser）
![alt text](images/cfa0d4b07e01fc85164b0fa47500455.jpg)

图5 气压分配器

##### 技术指标：
1. 吐出方式：16种自由设定方式、带吐出时间显示*
2. 自动定时吐出：00.01S-99.99S
3. 吐出间隔时间：0.1-9.9S（自动定时功能）
4. 输入电压：220V±10% 50Hz/110V±10% 60Hz
5. 内部电压：12VDC/24VDC
6. 输入气压：10-100pSi
7. 输出气压：1-80 pSi
8.  外形尺寸：235×225×63mm
9.  重量：2.8kg
##### 使用安装说明:
位于背部的SETUP四位吐出时间编程器拨码开关，通过拨动其可作16种出方式选择模式组合设定如下：
<table>
<capital>模式组合</capital>
<tr>
<th rowspan=2 align="center">序号</th>
<th colspan=4 align="center"> 模式开关状态</th>
<th rowspan=2 align="center">吐出方式及工作对应功能</th>
</tr>
<tr>
<th align="center">S1</th>
<th align="center">S2</th>
<th align="center">S3</th>
<th align="center">S4</th>
</tr>
<tr>
<th align="center">1</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="left">  点动模式，按下/踩下并保持以维持挤出</th>
</tr>
<tr>
<th align="center">2</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="left">  保持模式，按下/踩下1次开关，按照设定的时间持续挤出；再按下/踩下1次开关停止挤出。</th>
</tr>
<tr>
<th align="center">3</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="left">  点动计时模式，按下/踩下并保持以维持挤出设定的时间</th>
</tr>
<tr>
<th align="center">4</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="left">  按照设定的时间自动定时连续挤出</th>
</tr>
<tr>
<th align="center">5</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出1次。</th>
</tr>
<tr>
<th align="center">6</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出2次。</th>
</tr>
<tr>
<th align="center">7</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出3次。</th>
</tr>
<tr>
<th align="center">8</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出4次。</th>
</tr>
<tr>
<th align="center">9</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出5次。</th>
</tr>
<tr>
<th align="center">10</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出6次。</th>
</tr>
<tr>
<th align="center">11</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出7次。</th>
</tr>
<tr>
<th align="center">12</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出8次。</th>
</tr>
<tr>
<th align="center">13</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出9次。</th>
</tr>
<tr>
<th align="center">14</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出10次。</th>
</tr>
<tr>
<th align="center">15</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出11次。</th>
</tr>
<tr>
<th align="center">16</th>
<th align="center">Off</th>
<th align="center">Off</th>
<th align="center">On</th>
<th align="center">On</th>
<th align="left">  按下/踩下1次开关，按设定时间挤出12次。</th>
</tr>
</table>

实际使用的模式为序号1.

##### 操作：
1. 调压：通过调节黑色旋钮调节气压
2. 开关：可以按下左侧红色小按钮进行手动调节，也可以外接踏板手动调节（这个接口被改造用于程序控制）；控制方式在手册中有详细说明。
##### 参考资料
1. [手册](Docs/JND-983A点胶机详细功能设置.docx)

#### 2） 注射器针筒
##### 三维模型
1. [针筒](3Dmodels/SLDPRT/syringe.zip)
2. [喷嘴](3Dmodels/SLDPRT/tips.rar)
##### 手册
1. [喷嘴型号](Docs/技术表格.pdf)

### (3) 2D激光轮廓传感器（2D laser profile sensor）

![alt text](images/image-3.png)

图6 激光轮廓传感器

#### a. 概况：
使用的是基恩士2D激光轮廓传感器，驱动器型号为LJ-G5001，传感器型号为LJ-G030.

##### i. 驱动器：
驱动器基本安装尺寸如下所示：

![alt text](<images/image-5 (2).png>)

##### ii. 传感器：
1. 安装尺寸：

![alt text](<images/屏幕截图 2024-07-26 221343.png>)

2. 测量原理及测量范围
激光轮廓传感器采用激光三角反射式原理：激光束被放大形成一条激光线投射到被测物体表面上，反射光透过高质量光学系统，被投射到成像矩阵上，经过计算得到传感器到被测表面的距离（Z 轴）和沿着激光线的位置信息（X 轴）。移动被测物体或轮廓仪探头，就可以得到一组三维测量值。

![alt text](<images/屏幕截图 2024-07-26 221117.png>)

对于LJ-G030侧头，其有效测量区域为一个梯形，如下图所示：

![alt text](<images/image-2 (2).png>)

Z向测量范围：侧头下方30mm ± 10 mm；X向测量范围为 ±11 mm。

3. 测量精度：
Z向测量精度：1 μm. X向测量精度：5 μm。

![alt text](<images/屏幕截图 2024-07-26 221755.png>)

#### b. 通讯方式：

USB、串口、以太网。其中只有以太网通讯可以定制化传输轮廓数据。其他详情参见手册。
这里展示部分内容：

![alt text](<images/image-7 (2).png>)

![alt text](images/image-9.png)

#### 相关资料：
1. [用户手册](<Docs/01 AS_79826_LJ-G_UM_96M13960_CN_1059-7.pdf>)
2. [以太网通讯协议](<Docs/01 LJG5000_LAN.pdf>)
3. [LJ-G015 3D模型](Docs/LJ-G015(K)_2.x_t)
4. [LJ-G030 3D模型](Docs/LJ-G030_2.x_t)

## 3 硬件（Hardware）

这一节主要介绍接线和相关电路。

### (1) 控制板 Control borard
控制板采用了[创客基地(MakerBase)](https://makerbase.com.cn/)的[MKS-Monster8](https://github.com/makerbase-mks/MKS-Monster8)控制板。该控制板支持Marlin、Klipper等主流3D打印固件。

![alt text](images/控制板基本介绍.jpg)

基本技术参数如下：
- MCU: STM32F407VET6, 168MHz, 512K flash, 192KB RAM
- 供电：DC12-24V input(2 MP1584EN Output DC12V(For FANs) and DC5V)
- 3 PWM FANs + 3 power output(all power can be select by jumper and select VIN, dc12V, dc5V)
- axis drivers and 9 motor interface(Driver0,1,2-1,2-2,3,4,5,6,7)
- EXP1,EXP2 support MKS MINI12864,MKS TS35,LCD12864,LCD2004
- USART(usart1:PA9,PA10) support MKS H43 or for other serial communication
- 6 endstop support power select(X-,X+,Y-,Y+,Z-,Z+) and 3D TOUCH(PA8) interface
- 4K eeprom on board(connect to I2C)
- Built-in CAN transceiver and interface(connect to CAN)
- Integrated SPI communication microsd card and reserved SPI signal interface
- Integrated UDISK
- Integrated virtural USB device
- Support TMC UART and SPI mode, SENSORLESS_HOMING function(Diag0-5,connect to X-,Y-,Z-,X+,Y+,Z+)
- Support driver power select(5V or 3.3V)
- Has TVS power spike protection
- Possess power reverse connection protection function
- Support DFU mode set by button(Boot0)

![alt text](images/image-6.png)
![alt text](images/image-7.png)

但是，我们的平台需要使用的为X、Y、Z三轴的控制、无挤出加热需求、预留基板(substrate)的加热板(hot bed)，将风扇控制口留作气压开关(switch)控制，限位开关。综合上述考虑，大体的接线方案如下：

![alt text](images/接线-控制板.jpg)

接线图

![alt text](images/接线-控制板1.jpg)

接线图-补充

接下来我将结合这个整体接线图来说明各个部分是如何连接到控制板上的。

### (2) 电源 
电源用的就是很常见的220V交流输入，24V直流输出的电源。

![alt text](images/image-8.png)

图9 直流电源 Figure 9 DC power supply

### (3) 步进电机 Step Motors

所使用的点击为57步进电机。

步进电机首先与驱动器相连，驱动器需要接电源，并与控制板相连。

其控制方式为位置控制模式，即每发送一个脉冲，步进电机根据驱动器的设定转动特定的角度。对于57步进电机来说，步距角θ为0.8°（即1个脉冲对应电机轴转动0.8°），驱动可以设置系分数n，从而使得步距角变为θ/n，从而提高运动精度。只不过这种提升也是有限度的，通常认为细分数大于32时，对精度提升的效果会变得有限，细分数高于32时，主要的贡献在于提高运动的平稳性。

#### 驱动器

所使用的驱动器没有看到品牌和型号，但是将其设置面板抄了下来：

![alt text](images/接线-不进驱动.jpg)

可以通过调整驱动器的拨码开关来调整电流峰值和细分数。突出显示的是原有配置，我沿用了该配置。

#### 接线

原先的接线方式如下：

![alt text](images/原有线序-步进电机.jpg)

参照原有接线方式进行接线。需要指出的是，使用了一个转接板直插到控制板上，然后再进行接线，公共端（COM）接地，其他的包括使能（Enable）、脉冲（Pulus）、方向（Direction）。并且线缆颜色与下图一一对应：

![alt text](images/接线-步进电机.jpg)

### (4) 限位开关 Endstops

光电传感器，型号未知。根据原有接线方案调整：

![alt text](<images/原有线序-步进电机 - 副本.jpg>)

在实际调试过程中，发现原有的vcc 5V无法满足使用需要，有时候会出现电压不足的问题，且传感器上标识的工作电压为0~24V，因此选用24V电压作为供电。

可以在概览图中看到，在“接线图-补充”中，提到了Z+ endstop voltage selection, 在这里调整条线接法就能调整施加电压。

### (5) Hotbed
热床尺寸为210mm × 210mm

参考“接线图”进行接线即可，另外热床上有一个100k热敏电阻，需要借到“接线图-补充”中的TB处。

### (6) Pressure switch control

气压开关控制通过Controllable Fan端口控制，电压调整为24V，并接到继电器模块上，另外一端接到气压分配器(pressure dispenser)上，进而进行气压的开关控制(switch control)。

### (7) 传感器驱动器 Sensor Driver

![alt text](<images/image-3 (2).png>)

驱动器的接线方式参见上图：

①激光轮廓传感器需要接直流电源，电压为24V。

②可接显示器(VGA)观察轮廓信息。

③以太网口连接到路由器上从而与PC连接。也预留USB、RS232可以连接PC。

④传感器连接线。

## 4 Firmware - Marlin
[Marlin](https://marlinfw.org/)是最常用的开源3D打印固件，我们对其进行了相应修改，以满足设备使用：

1. 启用G05样条插补
2. 启用XYZ3个轴，并设定脉冲当量（每个轴移动1mm对应的脉冲数）
3. 关闭挤出机冷挤出限制（禁用温度传感器，设置最低挤出温度为0℃）
4. 按照实际行程范围调整配置打印范围。
5. 设置回零方向为X-，Y-，Z+

编程环境：VScode环境下使用PlatformIO插件。

Marlin官网：https://marlinfw.org/

原始Marlin资源：https://github.com/MarlinFirmware/Configurations/tree/release-2.1.2.4

定制Marlin资源：https://lecloud.lenovo.com/share/2JQMt9CWcRS9uVE4x （密码：pgjg）

## 5 软件 Software
这里分享使用的相关软件：

### （1）切片软件 Slicing software
#### 1）Slic3r
Slic3r是款开源切片软件，但是其已经停止开发了，所以存在一些bug。

官网：https://slic3r.org/

![alt text](images/scli3r.png)

图13 Slic3r界面

#### 2）PrusaSlicer

是Slic3r的一个分支，目前仍然在开发，并且其社区相对活跃。之前使用Slic3r，但是因为BUG太多，现在已经转为使用PrusaSlicer。

官网：https://www.prusa3d.com/page/prusaslicer_424/

![alt text](images/PrusaSlicer.png)

图14 PrusaSlicer界面

### （2）用户界面 user interface：pronterface   

官网：https://www.pronterface.com/

![alt text](images/pronterface.png)

图15 界面

### （3）LJ-Navigator

基恩士激光轮廓传感器的官方软件，可以用来测试传感器和配置相关参数。

![alt text](images/ljnavigator.png)

图16 界面

安装包：[LJ-Navigator](Docs/基恩士软件.rar)

### （4）CAXA 电子图版 2018 （中文版）
用于绘制打印、扫描轨迹

## 6 配置
### 电脑环境的配置
### 打印和挤出系统的配置
### 扫描系统的配置

## 7 程序和代码

## 8 Example (How to use)
### （1）打印一个立方体
### （2）获得一个截面轮廓
### （3）按照指定轨迹获取轮廓
### （4）设计打印轨迹并在打印后扫描，然后输出点云文件
