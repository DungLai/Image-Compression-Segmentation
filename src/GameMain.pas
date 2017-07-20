// Author: Tuan Dung Lai.
// StudentID: 101467732.
// Description: Custom program for unit "Intro to programming", unit code "COS10009", at Swinburne University of Technology.
// Semester 1, Year 2017.
// Tutor: Jonathon Meyers.
// Lecture: Dr. Matthew Mitchell, Prof. Sebastian Ng.
// External API: swinGame.  
// Language: pascal.

//						Reflection
// User can enter a range of byte that they want to compress to, then we have algorithm to determine the maximum number of color that is need to ensure that file size goes down to whaht user want
// Using Bilinear Interpolation to resize the image so that if user import an image which is too big, the program can display it 

program GameMain;
uses SwinGame, sgTypes, TerminalUserInput, SysUtils, Math;

const
	POINT_RADIUS = 5;
	X_DIFF = 20;		//location panel and point location
	Y_DIFF = 160;		//location panel and point location

type	
// type used for application  
	RGB 				= array[0..2] of Single;			// x-axis 	// store red, green and blue of an image
	CollumnPixels 		= array of RGB;						// y-axis, rowPixels
	imgArray 			= array of CollumnPixels;			// 3-dimensional array used to store red, green, blue color of each pixel in an image 
	IntArray			= array of Integer;					// label

	SingleColorArray	= array of Color;					// 1 dimensional array used to store color
	ColorArray 			= array of SingleColorArray;		// 2 dimensional array used to store color
// typed used for Visualization
	PointsRecord = Record
		x    : Single;										// x-axit on panel
		y    : Single;										// y-axit on panel
		idx  : Integer; 									// store label of each point, instead of create another array or enumeration to store it
	end;

	PointsArray = array of PointsRecord; 					// Store all the points on panel and the init points

// Setlength to 3-dimen array
procedure AddSize(var Img: ImgArray; row: Integer; col: Integer);
var
	i: Integer;
begin
	SetLength(Img, row);
	for i:=0 to row-1 do
	begin
		SetLength(Img[i], col);
	end;
end;

//return 3-dimensional array
function ReadImage(var filename: String): ImgArray;
var
	userBmp: Bitmap;
	row, col: Integer;
	i,j: Integer;
	c: Color;
begin
	WriteLn('Reading in image... Please wait...');

	userBmp := BitmapNamed(filename);

	row := BitmapHeight(userBmp);
	col := BitmapWidth(userBmp);

	AddSize(result, row, col);

	for i:=0 to row-1 do
	begin
		for j:=0 to col-1 do
		begin
			c := GetPixel(userBmp, j, i);
			result[i][j][0] := RedOf(c);
			result[i][j][1] := GreenOf(c);
			result[i][j][2] := BlueOf(c);
		end;
	end;
end;

//return width*height x 3, put all pixel into one array
function Reshape(var img: ImgArray): CollumnPixels; 
var
	row, col: Integer;
	i,j,rgb: Integer;
begin
	row := Length(img);
	col := Length(img[0]);

	SetLength(result, row*col);

	for i:=0 to col-1 do
	begin
		for j:=0 to row-1 do
		begin
			for rgb:=0 to 2 do
			begin
				result[i*row+j][rgb] := img[j][i][rgb]; 
			end;
		end;
	end;
	WriteLn('Reading in image successfully!');
end;

//return 3-dimensional array from two dimensional array
function InverseReshape(var imgSingle: CollumnPixels; row: Integer; col: Integer): ImgArray;
var
	i, j, rgb: Integer;
begin
	//SetLength to 3 dimensional matrix aka the result of the function according to row, col
	SetLength(result, row);
	for i:=0 to row-1 do
	begin
		Setlength(result[i], col);
	end;

	//Processing inverse reshape function
	for i:=0 to col-1 do
	begin
		for j:=0 to row-1 do
		begin
			for rgb:=0 to 2 do
			begin
				result[j][i][rgb] := imgSingle[i*row+j][rgb]; 
			end;
		end;
	end;
end;

//use random color later
function RandomInitColors(var colorNum: Integer): CollumnPixels;
var 
	c: Color;
	i: Integer;
begin
	SetLength(result, colorNum);
	for i:=0 to colorNum-1 do
	begin
		c := RandomColor();
		result[i][0] := RedOf(c);
		result[i][1] := GreenOf(c);
		result[i][2] := BlueOf(c);
	end;
end;

//return label for each pixels (form 0 to clusterNumber-1)
function ReadLabels(var imgSingle: CollumnPixels; initColor: CollumnPixels): IntArray;
var
	i,j,rgb: Integer;
	imgRow, initRow: Integer;
	distance, min: single;
begin
	imgRow := Length(imgSingle);
	initRow := Length(initColor);

	SetLength(result, imgRow);

	for i:=0 to imgRow-1 do
	begin
		// a random value that is big enough so that first distance value is always smaller than min
		min := 3*256*256;
		//loop through each pixels to calculate minimum distance
		for j:=0 to initRow-1 do
		begin
			distance := 0;
			// calculate distance in euculide space
			for rgb:=0 to 2 do
			begin
				distance += sqr(imgSingle[i][rgb]-initColor[j][rgb]);
			end;

			if (distance < min) then
			begin
				min := distance;
				result[i] := j;
			end;
		end;
	end;
end;

//calculate the in each cluster then return a vector contain the sum of these cluster
function SumInCluster(var imgSingle: CollumnPixels; idx: IntArray; clusterNum: Integer): CollumnPixels;
var
	i, rgb, lengthIdx: Integer;
begin
	Setlength(result, clusterNum);

	//assign initial value 
	for i:=0 to clusterNum-1 do
	begin
		for rgb:=0 to 2 do
		begin
			result[i][rgb] := 0;
		end;
	end;

	//cal total sum
	lengthIdx := Length(idx);
	for i:=0 to lengthIdx-1 do
	begin
		for rgb:=0 to 2 do
		begin
			result[idx[i]][rgb] += imgSingle[i][rgb];
		end;
	end;
end;

//return num_k
function CountCluster(var imgSingle: CollumnPixels; idx: IntArray; clusterNum: Integer): IntArray;
var
	i, rgb, lengthIdx: Integer;
begin
	Setlength(result, clusterNum);

	//assign initial value 
	for i:=0 to clusterNum-1 do
	begin
		for rgb:=0 to 2 do
		begin
			result[i] := 0;
		end;
	end;

	//check iteration of cluster 
	lengthIdx := Length(idx);
	for i:=0 to lengthIdx-1 do
	begin
		result[idx[i]] += 1;
	end;
end;

//assign new value to cluster after calculating the mean
procedure ReassignCluster(var initialColors: CollumnPixels; sum_k: CollumnPixels; num_k: IntArray);
var
	i, rgb: Integer;
begin
	for i:=0 to Length(initialColors)-1 do
	begin
		for rgb:=0 to 2 do
		begin
			if num_k[i] = 0 then
				initialColors[i][rgb] := 0
			else
				initialColors[i][rgb] := sum_k[i][rgb] / num_k[i];
		end;
	end;
end;

//return the imgSingle (all pixels in one row) after doing the algorithm
procedure AssignLabelToPixel(var imgSingle: CollumnPixels; idx: IntArray; finalCentroids: CollumnPixels);
var
	i, rgb: Integer;
begin
	for i:=0 to High(imgSingle) do
	begin
		for rgb :=0 to 2 do
		begin
			imgSingle[i][rgb] := finalCentroids[idx[i]][rgb];
		end;
	end;
end;

//return final centroids
function KMeansOnPixel(var img: ImgArray; clusterNum: Integer; iter: Integer; initialColors: CollumnPixels): ImgArray;
var
	//initialColors: CollumnPixels; //initial random colors 
	imgSingle: CollumnPixels; //2-dimensional array after reshape 3 dimensional array 
	num_k: IntArray; //  clusterNumx3
	sum_k: array of RGB; // sum off all pixel in same cluster  clusterNumx3
	i: Integer;
	idx: IntArray; // The label of each pixel (size = size(imgSingle)); value range from 0 to clusterNum-1
	row, col: Integer;
begin
	//convert to 2 dimensional array
	imgSingle := Reshape(img);

	row := Length(img);
	col := Length(img[0]);

	initialColors := RandomInitColors(clusterNum);

	WriteLn('...Running k means....');
	for i:=0 to iter-1 do
	begin
		//label of each picxel
		idx := ReadLabels(imgSingle, initialColors);

		//caculate means
		sum_k := SumInCluster(imgSingle, idx, clusterNum);
		num_k := CountCluster(imgSingle, idx, clusterNum);

		ReassignCluster(initialColors, sum_k, num_k);

		WriteLn('K-Means iteration '+ IntToStr(i+1) + '/' + IntToStr(iter) + '...');
	end;

	//reassign imgSingle
	AssignLabelToPixel(imgSingle, idx, initialColors);
	result := InverseReshape(imgSingle, row, col);
end;

//convert 3 dimensional RGB value to 2 dimensional type color
function RGBToColor(var img: ImgArray): ColorArray;
var
	row, col: Integer;
	i,j: Integer;
begin
	row := Length(img);
	col := Length(img[0]);

	//SetLength for colorarray (row and col size of imgArray);
	Setlength(result, row);
	for i:=0 to row-1 do
	begin
		Setlength(result[i], col);
	end;

	//begin converting using RGBFloatColor (swinGame API)
	for i:=0 to row-1 do
	begin
		for j:=0 to col-1 do
		begin
			result[i][j] := RGBFloatColor(img[i][j][0]/255, img[i][j][1]/255, img[i][j][2]/255);
		end;
	end;
end;

//pass by value function. Use this type to modify the bmp without changing the original one, in other way, we create a copy of the bitmap
function MatrixToBitmap(img: ImgArray): Bitmap;
var
	i, j: Integer;
	row, col: Integer;
	colorArr: ColorArray;
begin
	row := Length(img);
	col := Length(img[0]);

	result := CreateBitMap(col, row);
	colorArr := RGBToColor(img);

	for i:=0 to row-1 do
	begin
		for j:=0 to col-1 do 
		begin
			PutPixel(result, colorArr[i][j], j, i);
		end;
	end;
end;

//main funcion of the application
function KMeans(var filename: String; var clusterNum: Integer; var iter: Integer): Bitmap;
var
	img: ImgArray;	//3 dimensional array of image
	imgKMeans: ImgArray;
	initialColors: CollumnPixels;
	bmpOriginal: Bitmap;
begin
	// Return 3-dimen array
	img := ReadImage(filename);
	bmpOriginal := BitmapNamed(filename);

	initialColors := RandomInitColors(clusterNum);

	imgKMeans := KMeansOnPixel(img, clusterNum, iter, initialColors);

	result := MatrixToBitmap(imgKMeans);
end;

//Check button clicked by cordination
function ButtonClicked(X1, Y1, X2, Y2: Single): Boolean; 
var 
	X, Y, SumX, SumY: Single; 
begin 
	X := MouseX(); 
	Y := MouseY(); 
	SumX := X1 + X2; 
	SumY := Y1 + Y2; 
	result := false; 
	if MouseClicked(LeftButton) then
	begin 
		if (X >= X1) and (X <= SumX) and (Y >=Y1) and (Y <= SumY) then
		begin 	
			result := true; 
		end; 
	end; 
end;

//contain Visualization and Application
procedure IndexMenu(var isIndexMenu: Boolean; var isVisualization: Boolean; var isApplication: Boolean);
var 
	swinLogo: Bitmap;
begin
	swinLogo := BitmapNamed('swinLogo.png');
	repeat
		ProcessEvents();

		 	ClearScreen(ColorWhite);
		 	DrawFramerate(0,0);

		 	DrawBitmap(swinLogo, 10,20);

		 	//index
		 	DrawHorizontalLine(ColorBlack,130,10,1590);
		 	DrawTextOnScreen('Index Menu', ColorBlack, 'arial', 50, 650, 30);

		 	//button Visualization and button Application
		 	DrawRectangle(ColorBlack, 150, 300,200,50);
		 	DrawTextOnScreen('Visualization', ColorBlack, 'arial', 20, 170,320);
		 	DrawRectangle(ColorBlack, 950, 300,200,50);
		 	DrawTextOnScreen('Application', ColorBlack, 'arial', 20, 970,320);

		 	// check click button to go to other page (visualization or application)
		 	isVisualization := ButtonClicked(150,300,200,50);
		 	isApplication := ButtonClicked(950,300,200,50);

		 	if (isApplication = true) or (isVisualization = true) then
		 	begin
		 		isIndexMenu := false;
		 		break;
		 	end;

		 	RefreshScreen(60);
	until WindowCloseRequested();
end;

// transfer between Index, application and visualization menu
procedure BackButton(var isIndexMenu: Boolean; var isVisualization: Boolean; var isApplication: Boolean);
begin
	FillRectangle(ColorBlack, 1500,750,100,50);
	DrawTextOnScreen('Back', ColorWhite, 'arial',20,1520,770);
	if ButtonClicked(1500,750,100,50) then
	begin
		isIndexMenu := true;
		isApplication := false;
		isVisualization:= false;
		ReleaseAllResources();
	end;
end;

//
procedure ApplicationMenu(var isIndexMenu: Boolean; var isVisualization: Boolean; var isApplication: Boolean);
var 
	swinLogo: Bitmap;
	filename: String;
	clusterString, iterString: String; //used to readingtext then convert to int
	clusterNum, iter: Integer;
	isReadingFilename, isReadingCluster, isReadingIter: Boolean;
	bmpOriginal: Bitmap; //input image by user
	bmpKMeans: Bitmap; //compressed image
	CompressLogo: Bitmap; //click to run the k mean
	row, col: Integer; //row and col of the original image
	isFinishKmeans, isReadingName: Boolean;
	isSaved: Boolean; // is save new image after compression
	newName: String;
begin
	isReadingIter := true;
	isReadingCluster := true;
	isReadingFilename := true;
	clusterString := '';
	filename := '';
	iterString := '';
	isFinishKmeans := false;
	newName := '';
	isReadingName := false; //reading new name
	isSaved := false;
	CompressLogo := BitmapNamed('KmeansLogo.png');
	swinLogo := BitmapNamed('swinLogo.png');
	repeat
		ProcessEvents();

			ClearScreen(ColorWhite);
			DrawFramerate(0,0);

			DrawBitmap(swinLogo, 10,20);
		 	//index
		 	DrawHorizontalLine(ColorBlack,130,10,1590);
		 	DrawTextOnScreen('Application: Image Compression ', ColorBlack, 'arial', 50, 650, 30);
		 	BackButton(isIndexMenu, isVisualization, isApplication);

		 	if isIndexMenu then
		 		break;

		 	//file name textbox
		 	DrawTextOnScreen('Enter image filename: ',ColorBlack, 'arial',20,10,150);
		 	DrawRectangle(ColorBlack,220,150,200,30);	

		 	if (ButtonClicked(220,150,200,30) and (not ReadingText())) then
		 	begin
		 	    StartReadingText(ColorBlack,20,LoadFont('arial',20),230,155);
		 	    isReadingFilename := false;
		 	end;

	        if not ReadingText() and not isReadingFilename then
	        begin
	            filename := EndReadingText();
	            isReadingFilename := true;
	        end;

	        if filename <> '' then
	        begin
	        	DrawTextOnScreen('Confirm filename: '+ filename, ColorBlack, 'arial',20, 10, 185);
	       
	        	// Load and draw image based on filename 
	        	bmpOriginal := BitmapNamed(filename);

	        	//
	        	col := BitmapWidth(bmpOriginal);
	        	row := BitmapHeight(bmpOriginal);

	        	DrawBitmap(bmpOriginal,10,230);
	        end;

	        //Cluster number textbox
	        if filename <> '' then
		    begin
		        DrawTextOnScreen('Cluster (enter number): ', ColorBlack, 'arial', 20,500,150);
		        DrawRectangle(ColorBlack,720,150,50,30);

			 	if ButtonClicked(720,150,50,30) and not ReadingText() then
			 	begin
			 	    StartReadingText(ColorBlack , 3 ,LoadFont('Arial' ,20)  ,730 ,155 );
			 	    isReadingCluster := false;
			 	end;

		        if not ReadingText() and not isReadingCluster then
		        begin
		            clusterString := EndReadingText();
		        	isReadingCluster := true; 
		        end;

		        if clusterString <> '' then
		        begin
		        // Convert String to integer
		        clusterNum := StrToInt(clusterString);

		        DrawTextOnScreen('Confirm cluster: '+ IntToStr(clusterNum), ColorBlack, 'arial',20, 500, 185);
		        end;	
		    end;

		    //iteration textbox
		    if (filename <> '') and (clusterString <> '') then
		    begin
		    	DrawTextOnScreen('Iteration: ', ColorBlack, 'arial', 20,1000, 150);
		    	DrawRectangle(ColorBlack, 1100,150,50,30);

		    	if ButtonClicked(1100,150,50,30) and not ReadingText() then
		    	begin
		    		StartReadingText(ColorBlack, 2, LoadFont('arial', 20), 1110,155);
		    		isReadingIter := false;
		    	end;

		    	if not ReadingText() and not isReadingIter then
		    	begin
		    		iterString := EndReadingText();
		    		isReadingIter := true;
		    	end;

		    	if iterString <> '' then
		    	begin
		    		iter := StrToInt(iterString);
		    		DrawTextOnScreen('Confirm iteration: '+ IntToStr(iter), ColorBlack, 'arial', 20, 1000, 185);
		    	end;
		    end;

		    //draw kmean logo based on size of original image imported by user
		    if (iterString <> '') then
		    begin
		   		DrawBitmap(CompressLogo, col+10+20, 230);
		   		// if clicked to compressLogo then run the k mean and display the the image next to the original one

		   		if ButtonClicked(col+10+20, 230, BitmapWidth(CompressLogo), BitmapHeight(CompressLogo)) then
		   		begin
		   			DrawTextOnScreen('Compressing...', ColorBlack, 'arial', 20, col+10+20, 300);
		   			RefreshScreen(60);
		   			bmpKMeans := KMeans(filename, clusterNum, iter);
		   			isFinishKmeans := true;
		   		end;		
		   	end;

		   	// interaction of compressing logo
		   	if isFinishKmeans then
		   	begin
		   		DrawBitmap(bmpKMeans, col+170, 230);
		   		DrawTextOnScreen('Successfully!', ColorBlack, 'arial', 20, col+10+20, 300);
		   	//	RefreshScreen(60);
		   	end;

		   	// Saving button, allow user to choose their own name
		   	if isFinishKmeans then
		   	begin
		   		// border for button
		   		DrawRectangle(ColorBlack, 1399, 149, 132,32);
		   		FillRectangle(ColorGrey, 1400,150,130,30);
		   		DrawTextOnScreen('Save Image', ColorBlack, 'arial', 20, 1410,155);

		   		//click to enter name
			 	if ButtonClicked(1400,150,130,30) and not ReadingText() and not isReadingName then
			 	begin	
			 		isReadingName := true;
			 		isSaved := false;
			 	    StartReadingText(ColorBlack , 30 ,LoadFont('Arial' ,20)  ,1400 ,190);

			 	    //this newName='' is very important and is a very clever way, if i dont reset the value of newName, image will be save after pressing save image, or I have to have a lot of code to make it not overlap with the old name
			 	    newName := '';
			 	end;

			 	if isReadingName then
			 	begin
			 		DrawTextOnScreen('Enter new name:', ColorBlack, 'arial', 20, 1240,190);
		        end;

		        if not ReadingText() and isReadingName then
		        begin
		            newName := EndReadingText();
		        	isReadingName := false;
		        end;		   		

		        if (newName <> '') and (isReadingName = false) then 
		        begin
		        	DrawTextOnScreen('Successfully saved: '+ newName, ColorBlack, 'arial',20, 1250,190);
		        	RefreshScreen(60);
		        end;

		        if not (isSaved) and (newName <> '') then 
		        begin
		        	isSaved := true;
		        	SaveToPNG(bmpKMeans, newName);
		        end;
		   	end;

			RefreshScreen(60);
	until
		WindowCloseRequested();
end;

// return a color base on the index, 10 first colors were chosen based on the constrast. This algorithm should be improved by auto picking the color based on the constrast
function ToColor(var labelInt: Integer): Color;  
begin
	case labelInt of
		0: result := ColorWhite;
		1: result := ColorRed;
		2: result := ColorGreen;
		3: result := ColorBlue;
		4: result := ColorOrange;
		5: result := ColorPurple;
		6: result := ColorBrown;
		7: result := ColorPink;
		8: result := ColorGrey;
		9: result := ColorYellow;
		10: result := ColorBlueViolet;
		else result := RandomColor();
	end;
end;

//put color to points based on number and location of cluster
procedure DrawPointsWithLabel(var Points: PointsArray);
var
	i: Integer;
begin
	if Points[High(Points)].idx = 0 then
	begin
		for i:=0 to High(Points) do
		begin
			DrawCircle(ColorBlack, Points[i].x+20, Points[i].y+160, POINT_RADIUS);
		end;		
	end
	else
	begin
		for i:=0 to High(Points) do
		begin
			FillCircle(ToColor(Points[i].idx), Points[i].x+20, Points[i].y+160, POINT_RADIUS);
		end;
	end;
end;

//The panel where testing points are drawn
procedure DrawKMeansPanel();
begin
	DrawRectangle(ColorBlack, 20, 160, 900, 600);
end;

// add points to panel
procedure CreatingPointsButton(var isCreatingPoints: Boolean; var creatingPointsColor,creatingPointsColorText:Color);
begin
	// improve user experience by adding color when the creating point mode is on
 	if isCreatingPoints = true then
 	begin
 		FillRectangle(creatingPointsColor, 1020, 250, 200, 55);
 		DrawRectangle(ColorBlack, 1020, 250, 200, 55);
 	end
 	else 
 		DrawRectangle(creatingPointsColor, 1020, 250, 200, 55);

 	DrawTextOnScreen('Create points', creatingPointsColorText, 'arial', 30, 1025, 255);

 	if ButtonClicked(1020, 250, 200, 55) then
 	begin
 		//
 		if isCreatingPoints = false then
 		begin
 			isCreatingPoints := true;
 			creatingPointsColor := ColorGrey;
 			creatingPointsColorText := ColorWhite;
 		end
 		else 
 		begin
 			isCreatingPoints := false;
 			creatingPointsColor := ColorBlack;
 			creatingPointsColorText := ColorBlack;
 		end;
 	end;
end;

// check if mouse location is in the k-means panel or not
function isInPanel(const x : Single; const y: Single): Boolean;
begin
	if ((x>20) and (x<920) and (y>160) and (y<760)) then
		result := true
	else
		result := false;
end;

// Random location for initial cluster
function RandomInitClusterType1(var cluster: Integer): PointsArray;
var
	i: Integer;
begin
	SetLength(result, cluster);
	for i:=0 to cluster-1 do 
	begin
		//random location in panel
		result[i].x := RandomRange(20, 880);
		result[i].y := RandomRange(20, 580);

		//assign label 0 when not running k mean so that clusters will have white color
		result[i].idx := 0;
	end;
end;

// pick random current points on panel to be initial value of cluters
function RandomInitClusterType2(var cluster: Integer; Points: PointsArray): PointsArray;
var
	i, temp: Integer;
begin
	SetLength(result, cluster);
	for i:=0 to cluster-1 do
	begin
		temp := RandomRange(0, Length(Points)-1);
		result[i].x := Points[temp].x;
		result[i].y := Points[temp].y;
		result[i].idx := 0;
	end;
end;

//draw cluster in panel
procedure DrawClusters(var clusterArr: PointsArray);
var 
	i: Integer;
begin
	for i:=0 to High(clusterArr) do
	begin
		// Draw cluster by triangle with black border
		// border 1
		DrawTriangle(ColorBlack, clusterArr[i].x + X_DIFF, clusterArr[i].y-10 + Y_DIFF, clusterArr[i].x - 10 + X_DIFF, clusterArr[i].y+9 + Y_DIFF, clusterArr[i].x +10 + X_DIFF, clusterArr[i].y+9 + Y_DIFF);
		// border 2
		DrawTriangle(ColorBlack, clusterArr[i].x + X_DIFF, clusterArr[i].y-11 + Y_DIFF, clusterArr[i].x - 11 + X_DIFF, clusterArr[i].y+10 + Y_DIFF, clusterArr[i].x +11 + X_DIFF, clusterArr[i].y+10 + Y_DIFF);
		// fill rectangle by the color according to label
		FillTriangle(ToColor(clusterArr[i].idx), clusterArr[i].x + X_DIFF, clusterArr[i].y-8 + Y_DIFF, clusterArr[i].x - 8 + X_DIFF, clusterArr[i].y+7 + Y_DIFF, clusterArr[i].x +8 + X_DIFF, clusterArr[i].y+7 + Y_DIFF);
	end;
end;


//assign label to cluster, start with 1
procedure AssignInitClustersLabel(var Clusters: PointsArray);
var
	i: Integer;
begin
	for i:=0 to High(Clusters) do
	begin
		Clusters[i].idx := i+1;
	end;
end;

//calculate smallest distance and assign label 
procedure ClusterAssign(var Points: PointsArray; var Clusters: PointsArray);
var
	i,j: Integer;
	distance, min: Single;
begin
	for i:=0 to High(Points) do
	begin
		min := 900*900 + 600*600; //maximum distance in panel (the diagonal of the rectangle)
		for j:=0 to High(Clusters) do 
		begin
			distance := sqr(Points[i].x - Clusters[j].x);   // euclidean distance
			distance += sqr(Points[i].y - Clusters[j].y);   // euclidean distance

			// check for smallest distance and assign smallest distance as with label of both points and clusters
			if distance < min then 
			begin
				min := distance;
				Points[i].idx := j+1;		//assign label to points, label is 1-based index
			end;
		end; 
	end;
end;

// create a copy of cluter array to check convergence
function copyPointsArray(var Points: PointsArray): PointsArray;
var
	i: Integer;
begin
	Setlength(result, High(Points));
	for i:=0 to High(Points) do
	begin
		result[i].x := Points[i].x;
		result[i].y := Points[i].y;
	end;
end;

// check if the algo has converged by comparing the value of the clusters, if the location change means it's not converged. Then we break the loop
function isConverged(var Clusters: PointsArray; var ClustersCopy: PointsArray): Boolean;
var
	i: Integer;
begin
	result := true;
	for i:=0 to High(Clusters) do
	begin
		if ((Clusters[i].x <> ClustersCopy[i].x) or (Clusters[i].y <> ClustersCopy[i].y)) then
		begin
			result := false;
			break;
		end;
	end;
end;

//calculate square error (lost function)
function CalcSquareError(var Points: PointsArray; var Clusters: PointsArray): Single;
var 
	i: Integer;
begin
	result := 0;
	if ((Length(Points) <> 0) and (Length(Clusters) <> 0)) then
	begin
		if (Points[0].idx <> 0) and (Clusters[0].idx <> 0) then
		begin
			for i:=0 to High(Points) do
			begin
				result += sqr(Points[i].x - Clusters[Points[i].idx-1].x) + sqr(Points[i].y - Clusters[Points[i].idx-1].y);
			end;
		end;
	end;
end;

//Record on screen (Iterations, converge, square error)
procedure DrawRecord(var iter: Integer; var isConverged: Boolean; var squareError: Single; var Points: PointsArray);
begin
	DrawTextOnScreen('SquareError: '+ FloatToStr(squareError), ColorBlack, 'arial', 18, 1260, 250);
	DrawTextOnScreen('Iterations: ' + IntToStr(iter), ColorBlack, 'arial', 18, 1260, 270);
	DrawTextOnScreen('Number of points: ' + IntToStr(Length(Points)), ColorBlack, 'arial', 18, 1260, 290);

	if isConverged then
	begin
		DrawTextOnScreen('Converged!', ColorBlack, 'arial', 18, 1260, 310);
	end;
end;


// Get new value for each centroids, by calculating means of all points in each cluster 
procedure UpdateCentroids(var Points: PointsArray; var Clusters: PointsArray);
var 
	i: Integer;
	sums: PointsArray;	// total number of distance each cluster
	nums: array of Integer;	//number of time that cluster is assigned 
begin
	//initialize sum and k then increment later
	Setlength(sums, Length(Clusters));
	Setlength(nums, Length(Clusters));

	//initial value for sums and nums
	for i:=0 to High(sums) do
	begin
		sums[i].x := 0;
		sums[i].y := 0;
	end;		

	for i:=0 to High(nums) do
	begin
		nums[i] := 0;
	end;	

	//calculate sum and number that the cluster occurs
	for i:=0 to High(Points) do
	begin
		sums[Points[i].idx-1].x += Points[i].x;
		sums[Points[i].idx-1].y += Points[i].y;
		nums[Points[i].idx-1] += 1;
	end;

	//calculate means
	for i:=0 to High(Clusters) do
	begin
		if nums[i] <> 0 then
		begin
			Clusters[i].x := sums[i].x / nums[i];
			Clusters[i].y := sums[i].y / nums[i];
		end;
	end;
end;

procedure VisualizationMenu(var isIndexMenu: Boolean; var isVisualization: Boolean; var isApplication: Boolean);
var
	swinLogo: Bitmap;
	Points: PointsArray; 								// list of points on panel
	Clusters: PointsArray;
	i: Integer;
	isCreatingPoints, isReadingClusterNum: Boolean;
	creatingPointsColor, creatingPointsColorText: Color;
	members, clustersNum: Integer;						//number of point in panel and number of cluster
	clusterNumString: String;
	iter: Integer;										// Number of iteration of k means	
	ClustersCopy: PointsArray;							// A copy of clusters, used to check if converged
	isConvergedd: Boolean;
	squareError: Single;
begin
	Setlength(Points, 0);
	isCreatingPoints := false;
	isReadingClusterNum := true;
	creatingPointsColor := ColorBlack;
	creatingPointsColorText := ColorBlack;
	SetLength(Points, 0);
	clusterNumString := '';
	clustersNum := 0;
	iter := 0;
	isConvergedd := false;
	swinLogo := BitmapNamed('swinLogo.png');
	repeat
		ProcessEvents();

			ClearScreen(ColorWhite);
			DrawFramerate(0,0);

			DrawBitmap(swinLogo, 10,20);

		 	//index
		 	DrawHorizontalLine(ColorBlack,130,10,1590);
		 	DrawTextOnScreen('Visualization: K-Means Algorithm', ColorBlack, 'arial', 50, 650, 30);

		 	BackButton(isIndexMenu, isVisualization, isApplication);

		 	//main panel
		 	DrawKMeansPanel();
		 	// Option menu
		 	DrawRectangle(ColorBlack,1150, 150, 200, 45);
		 	DrawTextOnScreen('Menu Options', ColorBlack, 'arial', 30, 1155, 155);

		 	//Menu Boundary
		 	DrawRectangle(ColorBlack,990, 210, 510, 530); 

		 	//Create Point button
		 	CreatingPointsButton(isCreatingPoints, creatingPointsColor, creatingPointsColorText);

		 	//Init Cluster Button, accept user input for cluster number.
 			DrawRectangle(ColorBlack, 1020, 400, 200, 55);
 			DrawTextOnScreen('Cluster number:', ColorBlack, 'arial', 20, 1025, 405);

		 	if (ButtonClicked(1020, 400, 200, 55) and (not ReadingText())) then
		 	begin
		 	    StartReadingText(ColorBlack , 1 ,LoadFont('arial' ,20)  ,1185 ,405);
		 	    isReadingClusterNum := false;
		 	end;

	        if not ReadingText() and not isReadingClusterNum then
	        begin
	            clusterNumString := EndReadingText();
	        	isReadingClusterNum := true; 
	        end;

	        if clusterNumString <> '' then
	        begin
	        	// Convert String to integer
		        clustersNum := StrToInt(clusterNumString);

		        DrawTextOnScreen('You choose: '+ IntToStr(clustersNum), ColorBlack, 'arial',20, 1025, 425);
	        end;	

	        //Random init cluster label on screen
	        	// Type1 : Random points on panel
	        	// Type2 : Random points among Points
 			DrawTextOnScreen('Random Init Cluster', ColorBlack, 'arial', 20, 1030, 470);
	        
	        // random cluster type 1 and draw to panel;
	        DrawRectangle(ColorBlack, 1020, 500, 90, 55);
 			DrawTextOnScreen('Type 1', ColorBlack, 'arial', 15, 1035, 515);

 			if ButtonClicked( 1020, 500, 90, 55) then
 			begin
 				//change label of last index so that all points will displayed with no color
 				Points[High(Points)].idx := 0; 
 				//random init on panel
 				Clusters := RandomInitClusterType1(clustersNum);
 				//reset iteration
 				iter := 0;
 				//reset converge status
 				isConvergedd := false;
 			end;

 			// random cluster type 2 and draw to panel
 	        DrawRectangle(ColorBlack, 1020 + 20 + 90, 500, 90, 55);
 			DrawTextOnScreen('Type 2', ColorBlack, 'arial', 15, 1035 + 20 + 90, 515);
 			
 			if ButtonClicked(1020 + 20 + 90, 500, 90, 55) then
 			begin
 				//change label of last index so that all points will displayed with no color
 				Points[High(Points)].idx := 0; 
 				//random init on panel
 				Clusters := RandomInitClusterType2(clustersNum, Points);
 				//reset iteration
 				iter := 0;
 				//reset converge status
 				isConvergedd := false;
  			end;

  			// reset button 
  			DrawRectangle(ColorBlack ,1260, 600, 200, 55);
  			DrawTextOnScreen('RESET', ColorBlack, 'arial', 20, 1325, 610);

  			if ButtonClicked(1260,600,200,55) then
  			begin
  				// If press reset, calling the visualization menu (1 line of code) instead of set everything to 0
	 			VisualizationMenu(isIndexMenu, isVisualization, isApplication);
  			end;

 			//Running K-means button
 			DrawRectangle(ColorBlack,1020, 600, 200, 55);
 			DrawTextOnScreen('Running K-Means', ColorBlack, 'arial', 20, 1030, 610);

 			//if running kmean
 			if ButtonClicked(1020, 600, 200, 55) then
 			begin
 				// random init cluster and draw color of cluster based on constrast level
 				AssignInitClustersLabel(Clusters);

 				// Give color label to points on panel
 				ClusterAssign(Points, Clusters);

 				// Create a copy of the all current cluster after being updated, used to check if convereged or not

 				ClustersCopy := copyPointsArray(Clusters);
 				
 				UpdateCentroids(Points, Clusters);

 				if not isConverged(Clusters, ClustersCopy) then
 				begin
 					iter += 1;
 				end
 				else 
 				begin
					isConvergedd := true;	
 				end;
 			end;

 			//Draw iteration, converge status and square error on screen
 			squareError := CalcSquareError(Points, Clusters);
 			DrawRecord(iter, isConvergedd, squareError, Points);

 			// create Point
		 	if isCreatingPoints = true then
			begin
				// When cursor is in the panel, change from arrow to circle
				if isInPanel(MouseX(), MouseY()) then
				begin
					HideMouse();
					DrawCircle(ColorBlack, MouseX(), MouseY(), POINT_RADIUS);
				end
				else
					// when the cursor come out of the panel, use arrow cursor
					ShowMouse();

				// adding data to array when click in panel
				if (isInPanel(MouseX(), MouseY()) and MouseClicked(LeftButton)) then
				begin
					//reset iter
					iter := 0;
					//reset converge status
					isConvergedd := false;

					SetLength(Points, Length(Points)+1);
					Points[High(Points)].x := MouseX()-20;
					Points[High(Points)].y := MouseY()-160;
					Points[High(Points)].idx :=0;

					//reset square error
					Points[0].idx := 0;
					//reset label color
					if Length(Clusters) <> 0 then
					begin
						for i:= 0 to High(Clusters) do
						begin
							Clusters[i].idx := 0;
						end;
					end;
				end;
			end;

		 	if Length(Points) <> 0 then
		 		DrawPointsWithLabel(Points);

			//draw location of point
			if ((isCreatingPoints = false) and isInPanel(MouseX(),MouseY())) then
			begin
				DrawTextOnScreen('('+ FloatToStr(MouseX()-20) + ',' + FloatToStr(MouseY()-160) + ')', ColorBlack, 'arial', 15, Round(MouseX()), Round(MouseY()+15));
			end;

 			if clustersNum <> 0 then
 			begin	
 				DrawClusters(Clusters);
 			end;

		 	if isIndexMenu then
		 		break;

			RefreshScreen(200);
	until
		WindowCloseRequested();
end;

procedure Main();
var
	isIndexMenu, isVisualization, isApplication: Boolean;
begin
	OpenGraphicsWindow('Learning K-Means Algorithms', 1600, 800);
	//ShowSwinGameSplashScreen();

	// When first opening the program, the index will be shown first so I set isIndexMenu to true
	isIndexMenu := true; 
	isApplication := false;
	isVisualization := false; 

	repeat // The game loop...
	ProcessEvents();

	 	ClearScreen(ColorWhite);

	 	DrawFramerate(0,0);

	 	if isIndexMenu then
	 		IndexMenu(isIndexMenu, isVisualization, isApplication);

	 	if isApplication then
	 	begin
	 		ApplicationMenu(isIndexMenu, isVisualization, isApplication);
	 	end;

	 	if isVisualization then
	 	begin
	 		VisualizationMenu(isIndexMenu, isVisualization, isApplication);
	 	end;

	 	RefreshScreen(200);
	until WindowCloseRequested();
end;

begin
  Main();
end.

