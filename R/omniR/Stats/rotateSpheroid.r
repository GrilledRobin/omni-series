#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to move a point on the surface of a spheroid into another position on the same spheroid by rotating its  #
#   | coordinates on the 3 dimensions respectively                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The spheroid has the center as [0,0,0] and a standard form as [X^2 + Y^2 + Z^2 == 1]                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Reference]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Rotation on spheroid: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243          #
#   |[2] Rotation on ellipse: https://blog.csdn.net/u014779685/article/details/136454696                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate the new position of a point when only rotating it along the spheroidal surface in a 3D system                        #
#   |[2] If the moving is on a spheroid other than unit sphere, one may need to standardize it before using this function               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |X,Y,Z        :   Coordinate on 3D axes on the surface of a unit sphere                                                             #
#   |tolSurface   :   Tolerance when verifying whether the provided coordinates represents a point on the dedicated spheroid            #
#   |                 [<see def.>     ]  <Default> Use the system default tolerance level                                               #
#   |angleX,Y,Z   :   Angles (instead of arcs) to rotate the point on axes                                                              #
#   |                 [0.0            ]  <Default> Do not rotate the director                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<matrix>     :   matrix [N,3] where N is the number of elements in the provided vectors X, Y and Z                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241007        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |   |rlang                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

rotateSpheroid <- function(
	X,Y,Z
	,tolSurface = sqrt(.Machine$double.eps)
	,angleX = 0.0,angleY = 0.0,angleZ = 0.0
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#095. Verify whether the provided coordinates is on the surface of the dedicated spheroid
	spheroid <- X^2 + Y^2 + Z^2
	if (!is.logical(all.equal(spheroid, rlang::rep_along(spheroid, 1), tolerance = tolSurface))) {
		stop('[',LfuncName,']Some of the provided coordinates are not on the dedicated spheroids!')
	}

	#100. Initialize the position, to prevent any of them from being modified
	newX0 <- X
	newY0 <- Y
	newZ0 <- Z

	#200. Convert the angles into arcs
	rotX <- angleX * pi / 180.0
	rotY <- angleY * pi / 180.0
	rotZ <- angleZ * pi / 180.0

	#[ASSUMPTION]
	#[1] 球体坐标旋转推导: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243
	#[2] 坐标旋转公式: https://blog.csdn.net/u014779685/article/details/136454696
	#300. Rotate X
	newX1 <- newX0
	newY1 <- newY0 * cos(rotX) - newZ0 * sin(rotX)
	newZ1 <- newZ0 * cos(rotX) + newY0 * sin(rotX)

	#500. Rotate Y
	newY2 <- newY1
	newX2 <- newX1 * cos(rotY) + newZ1 * sin(rotY)
	newZ2 <- newZ1 * cos(rotY) - newX1 * sin(rotY)

	#700. Rotate Z
	newZ <- newZ2
	newX <- newX2 * cos(rotZ) - newY2 * sin(rotZ)
	newY <- newY2 * cos(rotZ) + newX2 * sin(rotZ)

	#900. Combine the arrays
	return(cbind(newX, newY, newZ))
}

#[Full Test Program;]
if (FALSE){
	#How to determine a point on the surface of a sphere
	if (TRUE){
		#100. Provide a random point in the system, in order to determine the rotation angles on the dedicated sphere
		posX <- 0.627 * (-1)
		posY <- 1.149 * (-1)
		posZ <- 2.118

		#200. Determine the size of the sphere
		rSphere <- 2.5

		#300. Calculate the attributes
		# [ASSUMPTION]
		# [1] 球面坐标变换 https://baike.baidu.com/item/%E7%90%83%E9%9D%A2%E5%9D%90%E6%A0%87%E5%8F%98%E6%8D%A2/22368776?fr=ge_ala
		rTempSphere <- sqrt(posX^2 + posY^2 + posZ^2)
		posTheta <- acos(posZ / rTempSphere)
		if (posX == 0) {
			posPhi <- pi / 2 * sign(posY)
		} else if (posY == 0) {
			posPhi <- pi / 2 * (1 - sign(posX))
		} else {
			posPhi <- atan(posY / posX)

			#500. Correct the attributes due to the limitation of arc triangular functions
			#[ASSUMPTION]
			#[1] The scenario [X == Y == 0] does not exist for a spherical calculation
			if (sign(posPhi) != sign(posY)) {
				posPhi <- posPhi + pi
			}
		}

		#800. Calculate the coordinates
		oldX <- round(rSphere * sin(posTheta) * cos(posPhi), 10)
		oldY <- round(rSphere * sin(posTheta) * sin(posPhi), 10)
		oldZ <- round(rSphere * cos(posTheta), 10)
		c(oldX, oldY, oldZ)
		# -0.629561, -1.153693, 2.126651
	}

	#Simple test
	if (TRUE){
		#100. Select a point on a sphere with radius as 2.5
		#[ASSUMPTION]
		#[1] If the spheroid is not a unit sphere, one has to standardize it, such as dividing each axis by their respective radius
		rSphere <- 2.5
		oldX <- -0.6295610254 / rSphere
		oldY <- -1.1536931709 / rSphere
		oldZ <- 2.1266511192 / rSphere

		#200. These numbers are values in Degrees instead of arcs
		rotX <- -17
		rotY <- -8
		rotZ <- 0

		#300. Rotate the sphere
		newPos <- rotateSpheroid(oldX,oldY,oldZ, tolSurface = 1e-6, angleX = rotX, angleY = rotY, angleZ = rotZ) * rSphere
		#            newX       newY     newZ
		# [1,] -0.9534183 -0.4815095 2.260341
	}
}
