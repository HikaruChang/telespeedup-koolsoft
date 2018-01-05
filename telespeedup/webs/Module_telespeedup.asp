<title>软件中心 - 家庭云提速</title>
<content>
<script type="text/javascript" src="/js/jquery.min.js"></script>
<script type="text/javascript" src="/js/tomato.js"></script>
<script type="text/javascript" src="/js/advancedtomato.js"></script>
<style type="text/css">
input[disabled]:hover{
    cursor:not-allowed;
}
</style>
<script type="text/javascript">
var dbus;
var softcenter = 0;
var _responseLen;
var noChange = 0;
var reload = 0;
var Scorll = 1;
get_dbus_data();
setTimeout("get_run_status();", 1000);
tabSelect('app1');

if (typeof btoa == "Function") {
  Base64 = {
    encode: function(e) {
      return btoa(e);
    },
    decode: function(e) {
      return atob(e);
    }
  };
} else {
  Base64 = {
    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    encode: function(e) {
      var t = "";
      var n, r, i, s, o, u, a;
      var f = 0;
      e = Base64._utf8_encode(e);
      while (f < e.length) {
        n = e.charCodeAt(f++);
        r = e.charCodeAt(f++);
        i = e.charCodeAt(f++);
        s = n >> 2;
        o = (n & 3) << 4 | r >> 4;
        u = (r & 15) << 2 | i >> 6;
        a = i & 63;
        if (isNaN(r)) {
          u = a = 64
        } else if (isNaN(i)) {
          a = 64
        }
        t = t + this._keyStr.charAt(s) + this._keyStr.charAt(o) + this._keyStr.charAt(u) + this._keyStr.charAt(a)
      }
      return t
    },
    decode: function(e) {
      var t = "";
      var n, r, i;
      var s, o, u, a;
      var f = 0;
      if (typeof(e) == "undefined"){
        return t = "";
      }
      e = e.replace(/[^A-Za-z0-9\+\/\=]/g, "");
      while (f < e.length) {
        s = this._keyStr.indexOf(e.charAt(f++));
        o = this._keyStr.indexOf(e.charAt(f++));
        u = this._keyStr.indexOf(e.charAt(f++));
        a = this._keyStr.indexOf(e.charAt(f++));
        n = s << 2 | o >> 4;
        r = (o & 15) << 4 | u >> 2;
        i = (u & 3) << 6 | a;
        t = t + String.fromCharCode(n);
        if (u != 64) {
          t = t + String.fromCharCode(r)
        }
        if (a != 64) {
          t = t + String.fromCharCode(i)
        }
      }
      t = Base64._utf8_decode(t);
      return t
    },
    _utf8_encode: function(e) {
      e = e.replace(/\r\n/g, "\n");
      var t = "";
      for (var n = 0; n < e.length; n++) {
        var r = e.charCodeAt(n);
        if (r < 128) {
          t += String.fromCharCode(r)
        } else if (r > 127 && r < 2048) {
          t += String.fromCharCode(r >> 6 | 192);
          t += String.fromCharCode(r & 63 | 128)
        } else {
          t += String.fromCharCode(r >> 12 | 224);
          t += String.fromCharCode(r >> 6 & 63 | 128);
          t += String.fromCharCode(r & 63 | 128)
        }
      }
      return t
    },
    _utf8_decode: function(e) {
      var t = "";
      var n = 0;
      var r = c1 = c2 = 0;
      while (n < e.length) {
        r = e.charCodeAt(n);
        if (r < 128) {
          t += String.fromCharCode(r);
          n++
        } else if (r > 191 && r < 224) {
          c2 = e.charCodeAt(n + 1);
          t += String.fromCharCode((r & 31) << 6 | c2 & 63);
          n += 2
        } else {
          c2 = e.charCodeAt(n + 1);
          c3 = e.charCodeAt(n + 2);
          t += String.fromCharCode((r & 15) << 12 | (c2 & 63) << 6 | c3 & 63);
          n += 3
        }
      }
      return t
    }
  }
}
//============================================

function get_dbus_data(){
	$.ajax({
	  	type: "GET",
	 	url: "/_api/telespeedup_",
	  	dataType: "json",
	  	async:false,
	 	success: function(data){
	 	 	dbus = data.result[0];
	  	}
	});
}

function get_run_status(){
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "telespeedup_status.sh", "params":[2], "fields": ""};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			if(softcenter == 1){
				return false;
			}
			document.getElementById("_telespeedup_status").innerHTML = response.result;
			setTimeout("get_run_status();", 3000);
		},
		error: function(){
			if(softcenter == 1){
				return false;
			}
			document.getElementById("_telespeedup_status").innerHTML = "获取运行状态失败！";
			setTimeout("get_run_status();", 5000);
		}
	});
}

function verifyFields(focused, quiet){
	if(E('_telespeedup_enable').checked){
		$('input').prop('disabled', false);
		$('select').prop('disabled', false);
	}else{
		$('input').prop('disabled', true);
		$('select').prop('disabled', true);
		$(E('_telespeedup_enable')).prop('disabled', false);
	}
	return true;
}

function toggleVisibility(whichone) {
	if(E('sesdiv' + whichone).style.display=='') {
		E('sesdiv' + whichone).style.display='none';
		E('sesdiv' + whichone + 'showhide').innerHTML='<i class="icon-chevron-up"></i>';
		cookie.set('ss_' + whichone + '_vis', 0);
	} else {
		E('sesdiv' + whichone).style.display='';
		E('sesdiv' + whichone + 'showhide').innerHTML='<i class="icon-chevron-down"></i>';
		cookie.set('ss_' + whichone + '_vis', 1);
	}
}

function tabSelect(obj){
	var tableX = ['app1-server1-jb-tab','app3-server1-rz-tab'];
	var boxX = ['boxr1','boxr3'];
	var appX = ['app1','app3'];
	for (var i = 0; i < tableX.length; i++){
		if(obj == appX[i]){
			$('#'+tableX[i]).addClass('active');
			$('.'+boxX[i]).show();
		}else{
			$('#'+tableX[i]).removeClass('active');
			$('.'+boxX[i]).hide();
		}
	}
	if(obj=='app3'){
		setTimeout("get_log();", 400);
		elem.display('save-button', false);
		elem.display('cancel-button', false);
	}else{
		elem.display('save-button', true);
		elem.display('cancel-button', true);
	}
}

function showMsg(Outtype, title, msg){
	$('#'+Outtype).html('<h5>'+title+'</h5>'+msg+'<a class="close"><i class="icon-cancel"></i></a>');
	$('#'+Outtype).show();
}

function save(){
	var para_chk = ["telespeedup_enable"];
	var para_inp = ["telespeedup_Info", "telespeedup_check_Qos", "telespeedup_Start_Qos", "telespeedup_Heart_Qos"];
	// collect data from checkbox
	for (var i = 0; i < para_chk.length; i++) {
		dbus[para_chk[i]] = E('_' + para_chk[i] ).checked ? '1':'0';
	}
	// data from other element
	for (var i = 0; i < para_inp.length; i++) {
		console.log(E('_' + para_inp[i] ).value)
		if (!E('_' + para_inp[i] ).value){
			dbus[para_inp[i]] = "";
		}else{
			dbus[para_inp[i]] = E('_' + para_inp[i]).value;
		}
	}
  // data need base64 encode
	var paras_base64 = ["telespeedup_check_Qos", "telespeedup_Start_Qos", "telespeedup_Heart_Qos"];
	for (var i = 0; i < paras_base64.length; i++) {
		if (typeof(E('_' + paras_base64[i] ).value) == "undefined"){
			dbus[paras_base64[i]] = "";
		}else{
			dbus[paras_base64[i]] = Base64.encode(E('_' + paras_base64[i]).value);
		}
	}
	//-------------- post dbus to dbus ---------------
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method":'telespeedup_config.sh', "params":["start"], "fields": dbus};
	var success = function(data) {
		$('#footer-msg').text(data.result);
		$('#footer-msg').show();
		setTimeout("window.location.reload()", 1000);
	};
	$('#footer-msg').text('保存中……');
	$('#footer-msg').show();
	$('button').addClass('disabled');
	$('button').prop('disabled', true);
	$.ajax({
	  type: "POST",
	  url: "/_api/",
	  data: JSON.stringify(postData),
	  success: success,
	  dataType: "json"
	});
}

function get_log(){
	$.ajax({
		url: '/_temp/telespeedup_log.txt',
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(response) {
			var retArea = E("_telespeedup_log");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				retArea.scrollTop = retArea.scrollHeight;
				if (reload == 1){
					setTimeout("window.location.reload()", 1200);
					return true;
				}else{
					return true;
				}
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 1000) {
				tabSelect("app1");
				return false;
			} else {
				setTimeout("get_log();", 200);
			}
			retArea.value = response.replace("XU6J03M6", " ");
			retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		},
		error: function() {
			E("_telespeedup_log").value = "获取日志失败！";
			return false;
		}
	});
}

</script>
<div class="box">
	<div class="heading">家庭云提速 0.1 内测版<a href="#/soft-center.asp" class="btn" style="float:right;border-radius:3px;margin-right:5px;margin-top:0px;">返回</a></div>
	<div class="content">
		<span class="col" style="line-height:30px;width:700px">
		Program:hiboy<br />
		Interface:Hikaru Chang (i@rua.moe)<br />
		Special thanks:fw867<br />
		欢迎使用【家庭云提速】提速电信宽带。<br />
		家庭云APP下载地址: <a href="http://home.cloud.189.cn/" target="_blank">http://home.cloud.189.cn/</a><br />
		抓取代码教程: <a href="http://koolshare.cn/thread-126377-1-1.html" target="_blank">http://koolshare.cn/thread-126377-1-1.html</a> | <a href="http://rt.cn2k.net/?p=389" target="_blank">http://rt.cn2k.net/?p=389</a><br />
		关于本插件的BUG反馈以及建议：<a href="https://github.com/hikaruchang/telespeedup-koolsoft" target="_blank"><u>Github</u></a> | <a href="mailto:i@rua.moe" target="_blank"><u>Email</u></a>
		</span>
	</div>
</div>
<ul class="nav nav-tabs">
	<li><a href="javascript:void(0);" onclick="tabSelect('app1');" id="app1-server1-jb-tab" class="active"><i class="icon-system"></i> 配置</a></li>
	<li><a href="javascript:void(0);" onclick="tabSelect('app3');" id="app3-server1-rz-tab"><i class="icon-info"></i> 日志</a></li>
</ul>
<div class="box boxr1" style="margin-top: 0px;">
	<div class="heading">配置</div>
	<hr>
	<div class="content">
	<div id="telespeedup-fields"></div>
	<script type="text/javascript">
		$('#telespeedup-fields').forms([
		{ title: '开启家庭云提速', name: 'telespeedup_enable', type: 'checkbox', value: dbus.telespeedup_enable == 1},
		{ title: '家庭云提速运行状态', text: '<font id="_telespeedup_status" name=telespeedup_status color="#1bbf35">正在获取运行状态...</font>' },
		{ title: '提速包选择', name: 'telespeedup_Info', type:'select', options:[['1','包1'],['2','包2'],['3','包3'],['4','包4'],['5','包5']], value: dbus.telespeedup_Info || "1", suffix: ' 默认包1，若有更好的提速包，可手动选择' },
		{ title: 'Check代码', name: 'telespeedup_check_Qos', type: 'textarea', value: Base64.decode(dbus.telespeedup_check_Qos) ||"",suffix: ' 请填写Check代码，例如：curl -H \'SessionKey: .....', style: 'width: 100%; height:150px;' },
		{ title: 'Start代码', name: 'telespeedup_Start_Qos', type: 'textarea', value: Base64.decode(dbus.telespeedup_Start_Qos) ||"",suffix: ' 请填写Start代码，例如：curl -H \'SessionKey: .....', style: 'width: 100%; height:150px;' },
		{ title: 'Heart代码', name: 'telespeedup_Heart_Qos', type: 'textarea', value: Base64.decode(dbus.telespeedup_Heart_Qos) ||"",suffix: ' 选填代码，Start后没提速可尝试填入，例如：curl -H \'SessionKey: .....', style: 'width: 100%; height:150px;' },
		]);
		$('#_telespeedup_enable').parent().parent().css("margin-left","-10px");
	</script>
	</div>
</div>

<div class="box boxr3">
	<div class="heading">运行日志</div>
	<div class="content">
		<div class="section telespeedup_log content">
			<script type="text/javascript">
				y = Math.floor(docu.getViewSize().height * 0.55);
				s = 'height:' + ((y > 300) ? y : 300) + 'px;display:block';
				$('.section.telespeedup_log').append('<textarea class="as-script" name="telespeedup_log" id="_telespeedup_log" wrap="off" style="max-width:100%; min-width: 100%; margin: 0; ' + s + '" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>');

			</script>
		</div>
	</div>
</div>
<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">保存 <i class="icon-check"></i></button>
<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">取消 <i class="icon-cancel"></i></button>
<span id="footer-msg" class="alert alert-warning" style="display: none;"></span>
<script type="text/javascript">init_telespeedup();</script>
</content>
