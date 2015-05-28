# ===== X-305 Daedalus Starship  version 3.1 =====

# instrumentation ===================================================
var lat_whole = props.globals.getNode("instrumentation/digital/lat-whole", 1);
var lat_fraction = props.globals.getNode("instrumentation/digital/lat-fraction", 1);
var lon_whole = props.globals.getNode("instrumentation/digital/lon-whole", 1);
var lon_fraction = props.globals.getNode("instrumentation/digital/lon-fraction", 1);
var heading_whole = props.globals.getNode("instrumentation/digital/heading-whole", 1);
var pitch_whole = props.globals.getNode("instrumentation/digital/pitch-whole", 1);
var vel_whole = props.globals.getNode("instrumentation/digital/velocity-whole", 1);
var alt_whole = props.globals.getNode("instrumentation/digital/altitude-whole", 1);
var agl_whole = props.globals.getNode("instrumentation/digital/agl-whole", 1);
var throttle_whole = props.globals.getNode("instrumentation/digital/throttle-whole", 1);
var altitude_mode = props.globals.getNode("instrumentation/digital/altitude-mode", 1);
var gui_altitude_node = props.globals.getNode("/sim/gui/dialogs/altitude", 1);
var altitude_modes = ["Feet","Meters"];
var combobox_a_apply = func {
	var caa = gui_altitude_node.getValue();
	for (var i = 0 ; i < size(altitude_modes) ; i += 1) {
		if (altitude_modes[i] == caa) {
			altitude_mode.setValue(i);
		}
	}
}

var head_mode = props.globals.getNode("instrumentation/digital/heading-mode", 1);
var gui_heading_node = props.globals.getNode("/sim/gui/dialogs/heading", 1);
var heading_modes = ["+- 180 degrees","360 degrees"];
var combobox_h_apply = func {
	var cah = gui_heading_node.getValue();
	for (var i = 0 ; i < size(heading_modes) ; i += 1) {
		if (heading_modes[i] == cah) {
			head_mode.setValue(i);
		}
	}
}

var vel_mode = props.globals.getNode("instrumentation/digital/velocity-mode", 1);
var gui_velocity_node = props.globals.getNode("/sim/gui/dialogs/velocity", 1);
var velocity_modes = ["MPS","Knots","MPH","KmPH", "Mach"];
var combobox_v_apply = func {
	var cav = gui_velocity_node.getValue();
	for (var i = 0 ; i < size(velocity_modes) ; i += 1) {
		if (velocity_modes[i] == cav) {
			vel_mode.setValue(i);
		}
	}
}

var gps_mode = props.globals.getNode("sim/lon-lat-format", 1);
var gui_gps_node = props.globals.getNode("/sim/gui/dialogs/gps", 1);
var gps_modes = ["DD.dddd","DD MM.mm","DD MM SS"];
var combobox_g_apply = func {
	var cag = gui_gps_node.getValue();
	for (var i = 0 ; i < size(gps_modes) ; i += 1) {
		if (gps_modes[i] == cag) {
			gps_mode.setValue(i);
		}
	}
}

instrumentation_update = func {
	if (getprop("sim/current-view/view-number") == 0) {
		#===== gps digital module ===================================
		var gpsmode = gps_mode.getValue();
		var xx = abs(getprop("position/latitude-deg"));
		lat_whole.setValue(int(xx));
		if (gpsmode == 2) {
			var gm = (xx - int(xx)) * 60;
			var gs = (gm - int(gm)) * 60;
			var ii = (int(gm) * 100) + int(gs);
			lat_fraction.setValue(ii);
		} elsif (gpsmode == 1) {
			var gm = (xx - int(xx)) * 6000;
			lat_fraction.setValue(int(gm));
		} else {
			var gm = (xx - int(xx)) * 10000;
			lat_fraction.setValue(int(gm));
		}
		var xx = abs(getprop("position/longitude-deg"));
		lon_whole.setValue(int(xx));
		if (gpsmode == 2) {
			var gm = (xx - int(xx)) * 60;
			var gs = (gm - int(gm)) * 60;
			var ii = (int(gm) * 100) + int(gs);
			lon_fraction.setValue(ii);
		} elsif (gpsmode == 1) {
			var gm = (xx - int(xx)) * 6000;
			lon_fraction.setValue(int(gm));
		} else {
			var gm = (xx - int(xx)) * 10000;
			lon_fraction.setValue(int(gm));
		}
		#===== heading digital module ===============================
		var hm = head_mode.getValue();
		var xx = getprop("orientation/heading-deg") * 10.0;
		if (xx < -0.5) { xx += 3600.0; }
		if (xx > 3599.5) { xx -= 3600.0; }
		heading_whole.setValue(int(xx + 0.5));
		var xx = getprop("orientation/pitch-deg") * 10.0;
		if (hm == 1) {
			if (xx < -0.5) { 
				xx += 3600.5; 
			} else {
				xx += 0.5;
			}
			pitch_whole.setValue(int(xx));
		} else {
			pitch_whole.setValue(int(abs(xx) + 0.5));
		}
		#===== velocity digital module ==============================
		var vm = vel_mode.getValue();
		var xx = int(abs(getprop("velocities/airspeed-kt")));		# Kts
		var knots_2_conv = [0.514444444, 1.0, 1.150779448, 1.852, 1.524];
		var ii = xx * knots_2_conv[vm];
		# calculating mach at fixed pressure and temperature for 755mph
		# actual speed of sound at: 60F = 760mph , -80F at 65,000ft = 650mph , at 100,000ft = 480mph
		vel_whole.setValue(ii);
		#===== altitude digital module ==============================
		var am = altitude_mode.getValue();
		var xx = abs(getprop("position/altitude-ft"));
		if (xx < 0) {
			var xx = 0;
		}
		if (am == 1) {
			var ii = xx * 0.3048;
			alt_whole.setValue(int(ii));
		} else {
			alt_whole.setValue(int(xx));
		}
			# unique property location for ufo model, 
			# change to /position/altitude-agl-ft for yasim or jsbsim
		var xx = abs(getprop("sim/model/daedalus/position/altitude-agl-ft"));
		if (xx < 0) {
		var xx = 0;
		}
		if (am == 1) {
			var ii = xx * 0.3048;
			agl_whole.setValue(int(ii));
		} else {
			agl_whole.setValue(int(xx));
		}
		#===== throttle digital module ==============================
		var xx = abs(getprop("controls/engines/engine/throttle")) * 100;
		throttle_whole.setValue(int(xx));
		#===================================
	}
}

instrumentation_loop = func {
	instrumentation_update();
	settimer(instrumentation_loop, 0);
}
settimer(instrumentation_loop, 2);

