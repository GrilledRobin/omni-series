#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to move a point on the surface of a spheroid into another position on the same spheroid by rotating its  #
#   | coordinates on the 3 dimensions respectively                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The spheroid has the center as [0,0,0] and a standard form as [X^2 + Y^2 + Z^2 == 1]                                           #
#   |[2] Direct3D and the plugin Element3D (from Video Copilot) for Adobe After Effects, as well as many other 3D modeling environments,#
#   |     use the <left-handed cartesian coordinates> to draw 3D objects.                                                               #
#   |    https://baike.baidu.com/item/%E5%B7%A6%E6%89%8B%E5%9D%90%E6%A0%87%E7%B3%BB/9171764?fr=ge_ala                                   #
#   |[3] Adobe After Effects draw video clips with <right-handed cartesian coordinates>                                                 #
#   |[4] The only factor that impacts the result is whether the point itself moves or the axes rotate                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Reference]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Rotation on spheroid: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243          #
#   |[2] Rotation on ellipse: https://blog.csdn.net/u014779685/article/details/136454696                                                #
#   |[3] Coordinate systems: https://zhuanlan.zhihu.com/p/672926406                                                                     #
#   |[4] Rotation on Right-handed system: https://blog.csdn.net/shenquanyue/article/details/103262512                                   #
#   |[5] Rotation on Left-handed system: https://blog.csdn.net/qq_20828983/article/details/81481437                                     #
#   |[6] DCM is the same of Left/Right, only different on the positive directions: https://zhuanlan.zhihu.com/p/677674288               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate the new position of a point when only rotating it along the spheroidal surface in a 3D system                        #
#   |[2] Attach the <light source> to the E3D objects in Adobe After Effects, to simulate a rotating Sun around the planet              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |X,Y,Z        :   Coordinate on 3D axes on the surface of a unit sphere                                                             #
#   |rotX,Y,Z     :   Arcs to rotate the axes                                                                                           #
#   |                 [0.0            ]  <Default> Do not rotate the vector                                                             #
#   |moveX,Y,Z    :   Values as coordinate to shift the vector                                                                          #
#   |                 [0.0            ]  <Default> Do not shift the vector                                                              #
#   |scaleX,Y,Z   :   Multipliers to scale the axes                                                                                     #
#   |                 [1.0            ]  <Default> Do not scale the axes                                                                #
#   |rotSeq       :   Sequence of the rotation on axes, currently only support <extrinsic> rotations, see official document of the      #
#   |                  Python method <scipy.spatial.transform.Rotation.from_euler>                                                      #
#   |                 [IMPORTANT] Different sequences result in different new positions                                                 #
#   |                 [xyz            ]  <Default> Rotate X axis, then Y, then Z                                                        #
#   |                 [Perm<x,y,z>    ]            Other permutations of the 3 axis names                                               #
#   |tolSurface   :   Tolerance when verifying whether the provided coordinates represents a point on the dedicated spheroid            #
#   |                 [<see def.>     ]  <Default> Use the generally sufficient tolerance level                                         #
#   |moveOf       :   Whether to move the point (holding the axes static) or rotate the axes (holding the position of the point)        #
#   |                 [A<xis>         ]  <Default> Rotate the axes by holding the position of the provided point                        #
#   |                 [P<oint>        ]            Move the point by holding the axes static                                            #
#   |invRotX,Y,Z  :   If True then the inverse of the rotation(s) is applied to the input vectors. Default is False.                    #
#   |                 [FALSE          ]  <Default> Rotate in the classic way                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<matrix>     :   matrix [N,3] where N is the number of elements in the provided vectors X, Y and Z                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241008        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20241009        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Corrected the logic by <Reference [6]>                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |rlang, magrittr                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |match.arg.x                                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, magrittr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

rotateSpheroid <- function(
	X,Y,Z
	,rotX = 0.0,rotY = 0.0,rotZ = 0.0
	,moveX = 0.0,moveY = 0.0,moveZ = 0.0
	,scaleX = 1.0,scaleY = 1.0,scaleZ = 1.0
	,rotSeq = 'xyz'
	,tolSurface = 1e-6
	,moveOf = c('Axis','Point')
	,invRotX = F,invRotY = F,invRotZ = F
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (length(rotX) != 1) stop('[',LfuncName,'][rotX] must be length-1 numeric value!')
	if (length(rotY) != 1) stop('[',LfuncName,'][rotY] must be length-1 numeric value!')
	if (length(rotZ) != 1) stop('[',LfuncName,'][rotZ] must be length-1 numeric value!')
	if (length(moveX) != 1) stop('[',LfuncName,'][moveX] must be length-1 numeric value!')
	if (length(moveY) != 1) stop('[',LfuncName,'][moveY] must be length-1 numeric value!')
	if (length(moveZ) != 1) stop('[',LfuncName,'][moveZ] must be length-1 numeric value!')
	if (length(scaleX) != 1) stop('[',LfuncName,'][scaleX] must be length-1 numeric value!')
	if (length(scaleY) != 1) stop('[',LfuncName,'][scaleY] must be length-1 numeric value!')
	if (length(scaleZ) != 1) stop('[',LfuncName,'][scaleZ] must be length-1 numeric value!')
	if (!is.logical(invRotX)) invRotX <- F
	if (!is.logical(invRotY)) invRotY <- F
	if (!is.logical(invRotZ)) invRotZ <- F
	moveOf <- match.arg.x(moveOf, arg.func = toupper)
	seqAxis <- strsplit(rotSeq, '')[[1]] %>% toupper()

	#020. Local environment
	if (moveOf == 'Axis') {
		coef_dir <- -1
	} else {
		coef_dir <- 1
	}

	#095. Verify whether the provided coordinates is on the surface of the dedicated spheroid
	spheroid <- X^2 + Y^2 + Z^2
	if (!is.logical(all.equal(spheroid, rlang::rep_along(spheroid, 1), tolerance = tolSurface))) {
		stop('[',LfuncName,']Some of the provided coordinates are not on the dedicated spheroids!')
	}

	#[ASSUMPTION]
	#[1] Below steps to create matrices use the <left-handed cartesian coordinates>, as it is popular in 3D development environment.
	#[2] 球体坐标旋转推导: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243
	#[3] 坐标系旋转变换公式图解 https://blog.csdn.net/panyonglin999/article/details/50083441
	#[4] 坐标的旋转变换和坐标系的旋转变换 https://blog.csdn.net/jc15988821760/article/details/133345301
	#[5] 右手坐标系 3d变换基础：平移、旋转、缩放（仿射变换）详解——公式推导 https://blog.csdn.net/shenquanyue/article/details/103262512
	#[6] 左手坐标系 3D坐标系中 点 的 平移、旋转和缩放 https://blog.csdn.net/qq_20828983/article/details/81481437
	#[7] 三维向量绕任意轴的旋转公式 https://blog.csdn.net/FreeSouthS/article/details/112576370
	#[9] 三个方向同时旋转，需要做矩阵乘法
	#100. Initialize the position into a matrix
	posOrg <- cbind(X,Y,Z,1)

	#200. Matrix to move the axes
	movMat <- rbind(
		c(               1.0,              0.0,              0.0,0.0)
		,c(              0.0,              1.0,              0.0,0.0)
		,c(              0.0,              0.0,              1.0,0.0)
		,c( coef_dir * moveX, coef_dir * moveY, coef_dir * moveZ,1.0)
	)

	#400. Rotation matrices, A.K.A Direction Cosine Matrix (DCM)
	#[ASSUMPTION]
	#[1] 欧拉角 https://blog.csdn.net/yq_forever/article/details/79558790
	#410. Coefficient matrix during rotation by holding X direction static
	rotMatX <- rbind(
		c(               1.0,              0.0,              0.0,0.0)
		,c(              0.0,        cos(rotX),        sin(rotX),0.0)
		,c(              0.0,       -sin(rotX),        cos(rotX),0.0)
		,c(              0.0,              0.0,              0.0,1.0)
	)

	#440. Coefficient matrix during rotation by holding Y direction static
	rotMatY <- rbind(
		c(         cos(rotY),              0.0,       -sin(rotY),0.0)
		,c(              0.0,              1.0,              0.0,0.0)
		,c(        sin(rotY),              0.0,        cos(rotY),0.0)
		,c(              0.0,              0.0,              0.0,1.0)
	)

	#470. Coefficient matrix during rotation by holding Z direction static
	rotMatZ <- rbind(
		c(         cos(rotZ),        sin(rotZ),              0.0,0.0)
		,c(       -sin(rotZ),        cos(rotZ),              0.0,0.0)
		,c(              0.0,              0.0,              1.0,0.0)
		,c(              0.0,              0.0,              0.0,1.0)
	)

	#495. Transpose the matrices if only the dedicated point on the provided (X,Y,Z) is to move
	if (moveOf == 'Point') {
		rotMatX %<>% t()
		rotMatY %<>% t()
		rotMatZ %<>% t()
	}

	#497. Make an inverse rotation on the dedicated axes as required
	#[ASSUMPTION]
	#[1] This is inspired by the different behavior in <VideoCopilot Element 3D> plugin for Adobe After Effects,
	#     where the rotation around Y axis is inverse to the classic algorithm
	if (invRotX) rotMatX %<>% t()
	if (invRotY) rotMatY %<>% t()
	if (invRotZ) rotMatZ %<>% t()

	#600. Matrix to scale the axes
	scaleMat <- rbind(
		c(            scaleX,              0.0,              0.0,0.0)
		,c(              0.0,           scaleY,              0.0,0.0)
		,c(              0.0,              0.0,           scaleZ,0.0)
		,c(              0.0,              0.0,              0.0,1.0)
	)

	#800. Rotation from different sequence of directions
	posNew <- posOrg
	for (i in seq_along(seqAxis)) {
		# posNew %<>% {. %*% get_values(paste0('rotMat', seqAxis[[i]]), mode = 'numeric')}
		posNew %<>% {. %*% get(paste0('rotMat', seqAxis[[i]]), mode = 'numeric')}
	}

	#900. Calculation under different coordinate systems
	#[ASSUMPTION]
	#[1] Below sequence during multiplication is important!
	#[2] We Eliminate the 4th dimension which indicates the object as a <point>, while NOT using <.subset> to prevent <unclass>ing
	#    https://sparkbyexamples.com/r-programming/subset-a-matrix-in-r/#google_vignette
	return(( posNew %*% movMat %*% scaleMat ) %>% {subset(., select = seq_len(ncol(.) - 1))})
}

#[Full Test Program;]
if (FALSE){
	#How to determine a point on the surface of a sphere
	if (TRUE){
		#100. Provide a random point in the system, in order to determine the rotation angles on the dedicated sphere
		posX <- 0.627 * (-1)
		posY <- 1.149
		posZ <- 2.118

		#200. Determine the size of the sphere
		rSphere <- 2.5

		#300. Calculate the attributes
		# [ASSUMPTION]
		# [1] 球面坐标变换 https://baike.baidu.com/item/%E7%90%83%E9%9D%A2%E5%9D%90%E6%A0%87%E5%8F%98%E6%8D%A2/22368776?fr=ge_ala
		rTempSphere <- sqrt(posX^2 + posY^2 + posZ^2)
		posTheta <- acos(posZ / rTempSphere)
		posPhi <- atan2(posY, posX)
		#Above usage of <arctan2> is exactly the same as below statements
		# if (posX == 0) {
		# 	posPhi <- pi / 2 * sign(posY)
		# } else if (posY == 0) {
		# 	posPhi <- pi / 2 * (1 - sign(posX))
		# } else {
		# 	posPhi <- atan(posY / posX)
		#
		# 	#500. Correct the attributes due to the limitation of arc triangular functions
		# 	#[ASSUMPTION]
		# 	#[1] The scenario [X == Y == 0] does not exist for a spherical calculation
		# 	if (sign(posPhi) != sign(posY)) {
		# 		posPhi <- posPhi + pi
		# 	}
		# }

		#800. Calculate the coordinates
		oldX <- round(rSphere * sin(posTheta) * cos(posPhi), 10)
		oldY <- round(rSphere * sin(posTheta) * sin(posPhi), 10)
		oldZ <- round(rSphere * cos(posTheta), 10)
		c(oldX, oldY, oldZ)
		# -0.629561, 1.153693, 2.126651
	}

	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Select a point on a sphere with radius as 2.5
		#[ASSUMPTION]
		#[1] If the spheroid is not a unit sphere, one has to standardize it, such as dividing each axis by their respective radius
		rSphere <- 2.5
		oldX <- -0.6295610254 / rSphere
		oldY <- 1.1536931709 / rSphere
		oldZ <- 2.1266511192 / rSphere
		oldPos <- c(oldX, oldY, oldZ)
		# -0.2518244  0.4614773  0.8506604
		centerAE <- c(1924.0, 1080.0, 0.0)
		centerAdj <- c(4.892923, 4.849852, 18.577313)
		oldPosAE <- oldPos * 640 * c(1,-1,1) + centerAE + centerAdj
		# [1] 1767.7253  789.5044  563.0000

		#200. These numbers are values in Degrees instead of arcs
		rot_X <- -5 * pi / 180.0
		rot_Y <- 7 * pi / 180.0
		rot_Z <- -36 * pi / 180.0
		newPosAE_to_be <- c(1699.69, 991.6018, 605.4006)
		newPosE3D_to_be <- (newPosAE_to_be - centerAE - centerAdj) / 640 / c(1,-1,1)
		# [1] -0.3581296  0.1457001  0.9169114  0.0000000

		#300. Move the point along the surface of the sphere, i.e. rotate the point
		#[ASSUMPTION]
		#[1] In <VideoCopilot Element 3D> plugin for Adobe After Effects, the rotation on Y axis is inverse to the classic behavior
		#[2] Meanwhile, the rotation sequence is <zyx>, i.e. rotating Z axis at first, then Y axis, and last X axis
		newPos <- rotateSpheroid(oldX,oldY,oldZ, rot_X, rot_Y, rot_Z, invRotY = T, rotSeq = 'zyx', moveOf = 'p')
		#            [,1]      [,2]      [,3]
		# [1,] -0.3677699 0.1458345 0.9184104
		newPosAE <- newPos * 640 * c(1,-1,1) + centerAE + centerAdj
		#         [,1]     [,2]     [,3]
		# [1,] 1693.52 991.5158 606.3599

		#700. Test the rotation of axes by holding the position of the provided point
		#[ASSUMPTION]
		#[1] <scipy> 中的坐标系是右手坐标系，同VTK、Blender
		#    https://blog.csdn.net/qq_45232776/article/details/140389687
		#[2] scipy中的“旋转”是保持给定的点不动而转动坐标轴
		axis_X <- -5 * pi / 180.0
		axis_Y <- 7 * pi / 180.0
		axis_Z <- -36 * pi / 180.0
		newPosAx_xyz <- rotateSpheroid(oldX,oldY,oldZ, axis_X, axis_Y, axis_Z, rotSeq = 'xyz', moveOf = 'a')
		#           [,1]      [,2]      [,3]
		# [1,] 0.1911697 0.5209957 0.8318759
		newPosAx_zxy <- rotateSpheroid(oldX,oldY,oldZ, axis_X, axis_Y, axis_Z, rotSeq = 'zxy', moveOf = 'a')
		#           [,1]      [,2]      [,3]
		# [1,] 0.1647533 0.5935176 0.7877774

		#785. The same result in Python
		if (F) {"
from scipy.spatial.transform import Rotation
import numpy as np
# 定义待旋转的点
point = np.array([-0.6295610254, 1.1536931709, 2.1266511192]) / 2.5
# 创建旋转对象
rotation = Rotation.from_euler('xyz', np.array([-5.0, 7.0, -36.0]), degrees = True)
# 执行旋转（注意：scipy中的“旋转”是保持给定的点不动而转动坐标轴）
rotated_point = rotation.apply(point)
print(rotated_point)

# 创建旋转对象
rotation = Rotation.from_euler('zxy', np.array([-36.0, -5.0, 7.0]), degrees = True)
# 执行旋转
rotated_point = rotation.apply(point)
print(rotated_point)
		"}

		#790. Verify the result by linear calculation
		#[ASSUMPTION]
		#[1] Reference: https://blog.csdn.net/shenquanyue/article/details/103262512
		#[2] Above article is for rotation of axes by holding the position of the vector
		#[3] Above article uses the <left-multiplication> hence the DCMs are transposed
		vfyMat <- cbind(
			(
				cos(axis_Y) * cos(axis_Z) * oldX
				+ (sin(axis_X) * sin(axis_Y) * cos(axis_Z) - sin(axis_Z) * cos(axis_X)) * oldY
				+ (sin(axis_Y) * cos(axis_X) * cos(axis_Z) + sin(axis_X) * sin(axis_Z)) * oldZ
			)
			,(
				cos(axis_Y) * sin(axis_Z) * oldX
				+ (cos(axis_X) * cos(axis_Z) + sin(axis_X) * sin(axis_Y) * sin(axis_Z)) * oldY
				+ (-sin(axis_X) * cos(axis_Z) + sin(axis_Z) * sin(axis_Y) * cos(axis_X)) * oldZ
			)
			,(
				-sin(axis_Y) * oldX
				+ sin(axis_X) * cos(axis_Y) * oldY
				+ cos(axis_X) * cos(axis_Y) * oldZ
			)
		)

		all.equal(vfyMat, newPosAx_xyz)
		# [1] TRUE
	}
}
