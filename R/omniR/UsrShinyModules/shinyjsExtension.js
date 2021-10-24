// Manually collapse the [box]-like container
// [ https://stackanswers.net/questions/r-shinyjs-shinydashboard-box-uncollapse-on-radionbuttons-input ]
shinyjs.collapse = function(boxid) {
	$('#' + boxid).closest('.box').find('[data-widget=collapse]').click();
};

// Share by Wang Chenyang 20200417
function getTextWidth(str, fontSize, fontFamily) {
	let result = 10;

	let ele = document.createElement('span');
	//字符串中带有换行符时，会被自动转换成<br/>标签，若需要考虑这种情况，可以替换成空格，以获取正确的宽度
	//str = str.replace(/\\n/g,' ').replace(/\\r/g,' ');
	ele.innerText = str;
	//不同的大小和不同的字体都会导致渲染出来的字符串宽度变化，可以传入尽可能完备的样式信息
	ele.style.fontSize = fontSize;
	ele.style.fontFamily = fontFamily;

	//由于父节点的样式会影响子节点，这里可按需添加到指定节点上
	document.documentElement.append(ele);

	result = ele.offsetWidth;

	document.documentElement.removeChild(ele);
	return result;
};

// [Quote: https://www.oschina.net/question/246699_120682 ]
/**
 * <li>Echarts 中axisLabel中值太长自动换行处理；经测试：360、IE7-IE11、google、火狐  * 均能正常换行显示</li>
 * <li>处理echarts 柱状图 x 轴数据显示根据柱子间隔距离自动换行显示</li>
 * @param title				将要换行处理x轴值
 * @param data				
 * @param fontSize			x轴数据字体大小，根据图片字体大小设置而定，此处内部默认为12	
 * @param barContainerWidth	柱状图初始化所在的外层容器的宽度
 * @param xWidth			柱状图x轴左边的空白间隙 x 的值，详见echarts文档中grid属性，默认80
 * @param x2Width			柱状图x轴右边的空白间隙 x2 的值，详见echarts文档中grid属性，默认80
 * @param insertContent		每次截取后要拼接插入的内容， 不传则默认为换行符：\n
 * @returns titleStr		截取拼接指定内容后的完整字符串
 * @author lixin
 */
 /*
 	20200415 Modified by Robin Lu Bin.
 	[datas]参数仅用于输入数据个数，计算过程不再参与
 	增加了参数[usrAxis]，如果[usrAxis == y]则不再对字符串大于3时的情况进行处理
 */
function getEchartBarXAxisTitle(title, datas, fontSize, barContainerWidth, xWidth, x2Width, usrAxis, insertContent = "\n"){
	
	if(!title || title.length == 0) {
		alert("截取拼接的参数值不能为空！");return false;
	}
	/*
	if(!datas || datas.length == 0) {
		alert("用于计算柱状图柱子个数的参数datas不合法！"); return false;
	}
	*/
	if(isNaN(barContainerWidth)) {
		alert("柱状图初始化所在的容器的宽度不是一个数字");return false;
	}
	if(!fontSize){
		fontSize = 12;
	}
	if(isNaN(xWidth)) {
		xWidth = 80;//默认与echarts的默认值一致
	}
	if(isNaN(x2Width)) {
		xWidth = 80;//默认与echarts的默认值一致
	}
	if(usrAxis != "y") {
		usrAxis = "x";
	}
	/*
	if(!insertContent) {
		// Below string is to be referenced by R, hence the character [\] inside [\n] should be escaped
		insertContent = "\\n";
	}
	*/
	var len_title = title.length;
	var xAxisWidth =  parseInt(barContainerWidth) - (parseInt(xWidth) + parseInt(x2Width));//柱状图x轴宽度=统计页面宽度-柱状图x轴的空白间隙(x + x2)
//	var barCount = datas.length;								//x轴单元格的个数（即为获取x轴的数据的条数）
	if(usrAxis == "x") {
		var barCount = datas;										//x轴单元格的个数（即为获取x轴的数据的条数）
		var preBarWidth = Math.floor(xAxisWidth / barCount);		//统计x轴每个单元格的间隔
		var preBarFontCount = Math.floor(preBarWidth / fontSize) ;	//柱状图每个柱所在x轴间隔能容纳的字数 = 每个柱子 x 轴间隔宽度 / 每个字的宽度（12px）
		if(preBarFontCount > 3) {	//为了x轴标题显示美观，每个标题显示留两个字的间隙，如：原本一个格能一样显示5个字，处理后一行就只显示3个字
			preBarFontCount -= 2;
		} else if(preBarFontCount <= 3 && preBarFontCount >= 2) {//若每个间隔距离刚好能放两个或者字符时，则让其只放一个字符
			preBarFontCount -= 1;
		}
	} else {
		var preBarFontCount = Math.floor(xAxisWidth / fontSize) ;
	};
	var newTitle = "";		//拼接每次截取的内容，直到最后为完整的值
	var titleSuf = "";		//用于存放每次截取后剩下的部分
	var rowCount = Math.ceil(len_title / preBarFontCount);	//标题显示需要换行的次数 
	if(rowCount > 1) {		//标题字数大于柱状图每个柱子x轴间隔所能容纳的字数，则将标题换行
		for(var j = 0; j < rowCount; j++) {
			/*
			if(j == 1) {
				
				newTitle += title.substring(0, preBarFontCount) + insertContent;
				titleSuf = title.substring(preBarFontCount);	//存放将截取后剩下的部分，便于下次循环从这剩下的部分中又从头截取固定长度
			} else {
				
				var startIndex = 0;
				var endIndex = preBarFontCount;
				if(titleSuf.length > preBarFontCount) {	//检查截取后剩下的部分的长度是否大于柱状图单个柱子间隔所容纳的字数
					
					newTitle += titleSuf.substring(startIndex, endIndex) + insertContent;
					titleSuf = titleSuf.substring(endIndex);	//更新截取后剩下的部分，便于下次继续从这剩下的部分中截取固定长度
				} else if(titleSuf.length > 0){
					newTitle += titleSuf.substring(startIndex);
				}
			}
			*/
			var tempStr = "";
			var start = j * preBarFontCount;
			var end = start + preBarFontCount;
			if (j == rowCount - 1) {
				tempStr = title.substring(start, len_title);
			} else {
				tempStr = title.substring(start, end) + insertContent;
			}
			newTitle += tempStr;
		}
	} else {
		newTitle = title;
	};
	return newTitle;
};

// [Quote: http://www.hanc.cc/index.php/archives/121/ ]
// [Quote: https://github.com/Hanson/newline-echarts ]
/**
 * Created by HanSon on 2016/1/24.
参数一：是你的option
参数二：是多少个字就换行
参数三：是x轴还是y轴 可选项 'yAxis' OR 'xAxis'
 */
function newline(option, number, axis){
    option[axis]['axisLabel']={
        interval: 0,
        formatter: function(params){
            var newParamsName = "";
            var paramsNameNumber = params.length;
            var provideNumber = number;
            var rowNumber = Math.ceil(paramsNameNumber / provideNumber);
            if (paramsNameNumber > provideNumber) {
                for (var p = 0; p < rowNumber; p++) {
                    var tempStr = "";
                    var start = p * provideNumber;
                    var end = start + provideNumber;
                    if (p == rowNumber - 1) {
                        tempStr = params.substring(start, paramsNameNumber);
                    } else {
                        tempStr = params.substring(start, end) + "\n";
                    }
                    newParamsName += tempStr;
                }
            } else {
                newParamsName = params;
            }
            return newParamsName
        }
    }
    return option;
};

// [Quote: http://c.biancheng.net/view/5547.html ]
// 为 String 扩展原型方法 byteLength()，该方法将枚举每个字符，并根据字符编码，判断当前字符是单字节还是双字节，然后统计字符串的字节长度。
String.prototype.byteLength = function() {  //获取字符串的字节数，扩展string类型方法
    var b = 0; len = this.length;  //初始化字节数递加变量并获取字符串参数的字符个数
    if(len) {  //如果存在字符串，则执行计划
        for(var i = 0; i < 1; i ++) {  //遍历字符串，枚举每个字符
            if(this.charCodeAt(i) > 255) {  //字符编码大于255，说明是双字节字符
                b += 2;  //则累加2个
            }else {
                b ++;  //否则递加一次
            }
        }
        return b;  //返回字节数
    } else {
        return 0;  //如果参数为空，则返回0个
    }
};
