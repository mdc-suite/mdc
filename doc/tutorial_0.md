# Multi-Dataflow Composer: dataflow and environment tutorial
This tutorial shows how to model applications through dataflow models by means of the Open RVC-CAL Composer environment, that is the same adopted by the Multi-Dataflow Composer (MDC).

## Dataflow Models


Input data for MDC is constituted by RVC-CAL dataflow models. The source files of the models can be:
* **XDF networks** - specifying how dataflow actors are connected together (LINK TO DOC FOR XDF);
* **CAL actors** - specifying the behavior of dataflow actors (LINK TO DOC FOR CAL).

## Test Case
In this tutorial a Sobel edge detector will be taken as test case Sobel edge detector basically returns the magnitude of the gradient related to the color spatial variation within the image. In particular, the gradient of the color spatial variation is calculated as the square root of the sum of the squared components of the spatial gradients, that are horizontal and vertical gradient:

$$
G = \sqrt{G_x^2+G_y^2}
$$

Horizontal and vertical gradients for a certain pixel are typically calculated through a bi-dimenstional convolution of a kernel (convolution matrix) by the image itself. Sobels adopts 3x3 kernels:

$$
G_x= 
\begin{bmatrix}
+1 & 0 & -1 \\
+2 & 0 & -2 \\
+1 & 0 & -1
\end{bmatrix}, 
G_y= 
\begin{bmatrix}
+1 & +2 & +1 \\
0 & 0 & 0 \\
-1 & -2 & -1
\end{bmatrix}
$$

Note that some variants of edge detection algorithms also consider as edge, instead of the gradient magnitude, its thresholded value: if the gradient is greater than a certain threshold, they return the maximum pixel value (e.g. 255), if not they return 0.

The dataflow model describing Sobel edge detector, involving both XDF networks and CAL actors, is available online at XXXXXX. _Sobel.xdf_ is composed with 26 different CAL actors:
- 1 forward actor to provide an additional frame necessary to the input image entirely;
- 2 line buffers to store input image rows;
- 6 delays  to store input image pixels;
- 4 shifter actors to realize a multiplication by two of the pixel value;
- 6 subtractors to compute partial sums of spatial gradients;
- 2 adders with 3 inputs to compute spatial gradients;
- 2 multipliers to square the spatial gradients;
- 1 adder with 2 inputs to compute the sum of the squared spatial gradients;
- 1 square root to compute the square root of the sum of the squared spatial gradients;
- 1 align actor necessary to drop all the spurious data. 

Basically, line buffers and delays provide a 3x3 matrix of pixels to be convolved with the kernel:

$$
\begin{bmatrix}
x_{00} & x_{01} & x_{02} \\
x_{10} & x_{11} & x_{12} \\
x_{20} & x_{21} & x_{22}
\end{bmatrix}
$$

Please note that the current pixel of the image, coming from the output of the forward actor, is in position (2,2) since input images are streamed row by row, element by element. Moreover, the gradient calculated on such pixel matrix will be referred to the pixel in position (1,1).

![sobel-dataflow](https://i.imgur.com/cGUG1h5.jpg)
Sobel dataflow model.

The dataflow models describing the test case adopted in the tutorial can be directly imported within the Eclipse runtime workspace running upon the MDC tool:
1. **Import Project** File > Import... > General > Exisiting Project into Workspace;
2. **Browse to** _test/Examples_ (**OK -> Finish**).

It is now possible to see the Orcc project containing the dataflow models to be used during the tutorial under the folders _src/baseline_ and  _src/common_. Besides _Sobel.xdf_ is present also _Testbench.xdf_. The testbench dataflow network is useful to simulate _Sobel.xdf_ since it connects this latter with two special actors (_SouceImage.cal_ and _ShowImage.cal_) allowing the reading of an image from a binary file and the displaying of the resulting edges on a display.
 
By double clicking dataflow networks or actors, it is possible to open the graphical environment, for the XDF networks, or the CAL editor, for the CAL actors, in order to analyze or modify them.

## Playing with Models
As introduced previously, the Orcc framework provides a powerful environmet to analyze, manipulate and simulate RVC-CAL dataflow models. In this section of the tutorial we are going to see how to draw and how to simulate dataflow models.

### Drawing Dataflow Models
Dataflow models can be drawn directly by the Orcc graphical interface. Indeed it is possible from there to add/remove/change actors, input/output and connections. Starting from the Sobel dataflow model, we are going to derive a new edge detector called Roberts. Roberts edge detector follows basically the same principle of Sobel, but it adopts different convolution matrices to compute spatial gradients. The matrices adopted by Roberts are 2x2:

$$
G_x= 
\begin{bmatrix}
0 & +1 \\
-1 & 0 
\end{bmatrix}, 
G_y= 
\begin{bmatrix}
+1 & 0 \\
0 & -1 
\end{bmatrix}
$$

With respect to Sobel, Roberts requires one less row and one less column of pixel for each convolution, that is for calculating the edge of each pixel. This means that several actors will not be necessary: 1 line buffer, 4 delays and 4 subtractors. Moreover, the matrix elements are all unary: no shift actor will be necessary. Also the adders with 3 inputs that were summing up the partial sums of the spatial gradients within Sobel are no more required, since only one partial sum will be necessary for Roberts. 

Let's derive Roberts edge detector from the Sobel one:
1. Firstly, it is necessary to **duplicate the _Sobel.xdf_ dataflow**:
    1. Right click on _Sobel.xdf_ and then press Copy
    2. Right click on the _src/baseline_ folder and then press Paste
    3. Type "Roberst.xdf" as new name within the Name Conflict window appearing after the paste operation
2. **Remove all unnecessary actors** (1 line buffer, 4 delays, 4 subtractors, 4 shifters, 2 adders)
    1. Double click on the just created _Roberts.xdf_ in order to open it with the graphical interface
    2. To **remove** one **actor instance** from the network move the cursor over it and click on the garbage can > click yes on the Confirm Delet window
    3. It is necessary to remove:
        - _line_x12_
        - _del_x11_, _del_x01_, _del_x21_, _del_x20_
        - _sh_x01_, _sh_x10_, _sh_x21_, _sh_x12_
        - _sub_h1_, _sub_h2_, _sub_v1_, _sub_v2_
        - _add_h_, _add_v_
3. In order to respect the name conventions, some **actor instances should be renamed** by right clicking on them, select "Show properties" and modify the "Name:" field:
    1. _fwd_x22_ becomes _fwd_x11_  
    2. _line_x02_ becomes _line_x01_
4. **Disconnect wrong connections** by right clicking on the connection and selecting "Delete"
    1. delete connection from port _dataOut_ of _del_x00_ to port _opA_ of _sub_h0_
6. Then **unconnected actor instances have to be connected** by **drawing a line** from one of the source instance ports to one of the destination instance port: 
    1. connect port _outY_ of _fwd_x11_ to port _Y_ of _line_x01_
    2. connect port _outY_ of _fwd_x11_ to port _dataIn_ of _del_x10_
    3. connect port _Line_ of _line_x01_ to port _dataIn_ of _del_x00_
    4. connect port _dataOut_ of _del_x10_ to port _opA_ of _sub_h0_
    5. connect port _outY_ of _fwd_x11_ to port _opB_ of _sub_v0_
    6. connect port _sub_ of _sub_h0_ to port _opA_ of _mul_h_
    7. connect port _sub_ of _sub_h0_ to port _opB_ of _mul_h_
    8. connect port _sub_ of _sub_v0_ to port _opA_ of _mul_v_
    9. connect port _sub_ of _sub_v0_ to port _opB_ of _mul_v_
7. **Change entity of actor instances that are different going from Sobel to Roberts** by right clicking on the actor instance, select "Set/updated refinement" and then the new actor for the instante under modification: 
    1. update actor of instance _fwd11_ from _Forward3x3.cal_ to  _Forward2x2.cal_
    2. update actor of instance _aln_ from _Align3x3.cal_ to  _Align2x2.cal_

Now the dataflow model _Roberts.xdf_ should be implementing the desired functionality, by convolving input pixels with the convolution matrices in order to extract spatial gradients and, in turn, detect edges of the incoming image.

![roberts-dataflow](https://i.imgur.com/zLR5hDs.jpg)
Roberts dataflow model.

### Simulating Dataflow Models
In this section we are going to see how to simulate dataflow models within the Orcc environment. This feature could be very powerful since it allows users to analyze applications at a very high level of abstraction.

Simulating dataflow models requires special actors serving as source and destination of the flow of tokens. Basically, simulation can be obtained by employing standard or native actor instances. The former are actors fully specified in CAL. The latter are actors not fully specified in CAL, but with references to the underlying Java source code, in order to achieve complex task (e.g. open or display an image). 

In this tutorial we are going to see both examples of simulations with native or standard actor instances.

In order to simulate a dataflow model it is then necessary to bound it with source and destination actors. At this purpose, two additional dataflow models are present in the _src/baseline_ folder: _TestbenchDummy.xdf_ and _Testbench.xdf_. The former employs only standard actors, while the latter adopts also native actors. To analyze more in details testbenches double click on them. In the graphical interface will appear a dataflow co
mposed with two blue vertices, that are actor instances, and one yellow vertex, that is a network instances: it instantiates a dataflow in turn. As usual, by double clicking on one instance the corresponding entity will be opened: a CAL actor for blue instances, an XDF network for yellow instances.

![testbench-dataflow](https://i.imgur.com/PTiYOU1.jpg)
Testbench dataflow model.

#### Simulating with dummy source and destination (MISSING MODULES IN FOLDERS)
To simulate the dataflow model with dummy source and destination actors, it is not required any additional input for the model, but all the information embedded within the source actor _SourceImageDummy.cal_. By double clicking on it, it is possible to see how, after sending from port _SizeOfImage_ the size of image in terms of width and heigth (by default set to 300 and 225 pixels respectively), this actor simply send from port _Y_ pixels with value equal to the corresponding image row index. The destination actor instead is simply in charge of printing the value of the pixel received from port _Y_ in the console, together with its row and column indeces. In order to work properly, it also requires receiving the size of image from port _SizeOfImage_ before receiving pixels.

To launch a new dataflow simulation, it is necessary to create an Eclipse run configuration:

1. **Create a new run configuration** Run > Run configurations..., double click on Orcc simulation;
    1. **Name** choose a name for the configuration ("New Configuration" by default, set it to "Dummy Simulation");
    2. **Project** select _Tutorials_ project;
    3.  **Simulator** select _Visitor interpreter and debugger_ simulator;
    5.  **Options**:
        1.  **XDF name** select the name of the testbench you want to simulate (in this case _TestbenchDummy.xdf_);
        2. **Input stimulus** select one random file (it will be not used during this kind of simulation); 
        3. **Output file directory** select an output file directory where the output files (if any) will be stored;
2. **Run** the configuration.

At this point, the simulation will start and in the console will appear the corresponding output. The same output can be analyzed and checked in order to understand if everything is going well in the developed system. Other options are also available and allow users to provide a golden reference to some outputs, to perform casts on data, to profile the execution or to extract execution traces. Further documentation related to these additional simualtion features is available on the [Orcc website](https://orcc.sourceforge.net/). 

#### Simulating with native source and destination
The simulation with native source and destination actor instances is quite similar to the one with dummy source and destination. The only difference is that native actors are capable of actually read files and display images in order to accomplish the original goal of the test case.

It is necessary to launch also in this case a dataflow simulation. Like in the previous simulation, an Eclipse run configuration has to be created:

1. **Create a new run configuration** Run > Run configurations..., double click on Orcc simulation;
    1. **Name** choose a name for the configuration ("New Configuration" by default, set it to "Real Simulation");
    2. **Project** select _Tutorials_ project;
    3.  **Simulator** select _Visitor interpreter and debugger_ simulator;
    5.  **Options**:
        1.  **XDF name** select the name of the testbench you want to simulate (in this case _Testbench.xdf_);
        2. **Input stimulus** select the _gear.bin_ input file within the directory _referece/baseline_ of the _Tutorials_ folder (note that now this file will be read by the _SourceImage.cal_ actor and sent to the _dut_ netwrok instance); 
        3. **Output file directory** select an output file directory where the output files (if any) will be stored;
2. **Run** the configuration.

After a couple of seconds a display window will appear, launched by the _ShowImage.cal_ actor, in order to show the edges of the image detected with the Sobel algorithm.

![original-image-example](https://i.imgur.com/kV6ZAn0.png) 
Original image.

![sobel-processed-example](https://i.imgur.com/PWQIWAX.png)
Processed image after Sobel edge detection.


By simply changing the _dut_ network instance from Sobel to Roberts it is possible to simulate the Roberts dataflow and obtain the resulting edge image:

1. **Change** the _dut_ **network instance** 
    1. **Open the tesbench** by double clicking on _Testbench.xdf_ file;
    2. **Update the network instance**
        1. Right click on the _dut_ network instance > Set/Update refinement;
        2. Choose the baseline.Roberts network as new entity for the instance;
2. **Change** the simulation **input file**
    1. Run > Run configurations..., select the "Real Simulation" run configuration;
    2. In the Input stimulus field browse to the _Roberts.bin_ file in order to update it;
3. **Run** the configuration.

As for the Sobel dataflow, a display window will appear showing the edges detected by the Roberts algorithm.


![roberts-processed-example](https://i.imgur.com/JBCkJkF.png)
Processed image after Roberts edge detection.

## Try it yourself!
It is possible to derive other edge detection dataflow and to try them with the same testbench used for Sobel and Roberts.

### Change Kernel
There are two other simple edge detectors that are basically equal to Sobel but they adopt different kernels to calculate the spatial gradients. These detectors are called Prewitt and Scharr. 

The Prewitt gradient calculation kernels are:

$$
G_x= 
\begin{bmatrix}
+1 & 0 & -1 \\
+1 & 0 & -1 \\
+1 & 0 & -1
\end{bmatrix}, 
G_y= 
\begin{bmatrix}
+1 & +1 & +1 \\
0 & 0 & 0 \\
-1 & -1 & -1
\end{bmatrix}
$$

The Scharr gradient calculation kernels:

$$
G_x= 
\begin{bmatrix}
+3 & 0 & -3 \\
+10 & 0 & -10 \\
+3 & 0 & -3
\end{bmatrix}, 
G_y= 
\begin{bmatrix}
+3 & +10 & +3 \\
0 & 0 & 0 \\
-3 & -10 & -3
\end{bmatrix}
$$

Note that the multiplication by 3 for the Scharr kernels could be obtained in different ways: it is possible to create a new actor acting as multiplier or to use the already available actors (e.g. shifter and adder).

### Change Algorithm
Another possiblity to derive additional edge detectors is to consider algorithms that do not take as edge of the image the spatial gradient directly, but that apply a threshold to it and normalize the outputs to black (0) and white (255) values depending on the fact that the corresponding input is below or above the threshold respectively. A typical value for the threshold is 80.

Note that to derive thresholded edge detectors it is necessary to create a new actor in charge of performing the comparison of the spatial gradient with the threshold and the corresponding normalization to 0 or 255.

**Next tutorial:** baseline feature (ADD LINK).
