# ====== Daedalus  version 5.01 for FlightGear 1.9 (minimum) =====

# beacons -----------------------------------------------------------
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/daedalus/lighting/beacon1", [0.875, 0.79], beacon_switch);

# Hull and fuselage colors and livery ====================================
aircraft.livery.init("Aircraft/daedalus/Models/Liveries");

# config file entries ===============================================
# save livery choice in your config file to autoload next start
aircraft.data.add("sim/model/livery/name");
aircraft.data.add("sim/model/daedalus/shadow");
aircraft.data.add("sim/model/daedalus/logo/texture");

# Add second popupTip to avoid being overwritten by primary joystick messages ===
var tipArg2 = props.Node.new({ "dialog-name" : "PopTip2" });
var currTimer2 = 0;
var popupTip2 = func {
	var delay2 = if(size(arg) > 1) {arg[1]} else {1.5};
	var tmpl2 = { name : "PopTip2", modal : 0, layout : "hbox",
		y: gui.screenHProp.getValue() - 110,
		text : { label : arg[0], padding : 6 } };

	fgcommand("dialog-close", tipArg2);
	fgcommand("dialog-new", props.Node.new(tmpl2));
	fgcommand("dialog-show", tipArg2);

	currTimer2 = currTimer2 + delay2;
	var thisTimer2 = currTimer2;

		# Final argument is a flag to use "real" time, not simulated time
	settimer(func { if(currTimer2 == thisTimer2) { fgcommand("dialog-close", tipArg2); } }, delay2, 1);
}

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

#==========================================================================
#             === define global nodes and constants ===

# view nodes and offsets -------- x/y/z == right/up/aft -------------------
var zNoseNode = props.globals.getNode("sim/view/config/y-offset-m", 1);
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var zViewNode = props.globals.getNode("sim/current-view/y-offset-m", 1);
var hViewNode = props.globals.getNode("sim/current-view/heading-offset-deg", 1);

# nav lights --------------------------------------------------------
var nav_lights_state = props.globals.getNode("sim/model/daedalus/lighting/nav-lights-state", 1);
var nav_light_switch = props.globals.getNode("sim/model/daedalus/lighting/nav-light-switch", 1);

# landing lights ----------------------------------------------------
var landing_light_switch = props.globals.getNode("sim/model/daedalus/lighting/landing-lights", 1);

# doors -------------------------------------------------------------
var doors = [];
var walker_on_door = { door_number: -1, last_position: 0.0};

# engines glow and main systems -------------------------------------
	# engine refers to atmospheric engines
	# /sim/model/daedalus/lighting/engine-glow is a combination of engine sounds
	# anti-grav can provide hover capability (exclusively under 100 kts)
	# center large engines are separate in this model, and provide velocities over 1000 kts
	# ftl hyperdrive glows are just for show, and are visible once above the atmosphere and at higher speeds.

# movement and position ---------------------------------------------
var airspeed_kt_Node = props.globals.getNode("velocities/airspeed-kt", 1);
var abs_airspeed_Node = props.globals.getNode("velocities/abs-airspeed-kt", 1);

# maximum speed for ufo model at 100% throttle ----------------------
var maxspeed = props.globals.getNode("engines/engine/speed-max-mps", 1);
var speed_mps = [1, 20, 50, 100, 200, 500, 1000, 2000, 5000, 11177, 20000, 50000];
# level 9 maximum speed 11176mps is 25000mph. aka escape velocity.
# level 10 is not really useful without interplanetary capabilities,
#  and is not allowed below the boundary to space.
var limit = [1, 5, 6, 7, 2, 5, 6, 11];
var current = props.globals.getNode("engines/engine/speed-max-powerlevel", 1);

# VTOL anti-grav ----------------------------------------------------
var joystick_elevator = props.globals.getNode("input/joysticks/js/axis[1]/binding/setting", 1);
var antigrav = { input_type: 0, momentum_watch: 0, momentum: 0, up_factor: 0, request: 0 };
	# input_type ; 1 = keyboard, 2 = joystick, 3 = mouse
	# request = for during startup, includes timer to cancel request if no further requests are made. Returns to zero after complete.

# ground detection and adjustment -----------------------------------
var altitude_ft_Node = props.globals.getNode("position/altitude-ft", 1);
var ground_elevation_ft = props.globals.getNode("position/ground-elev-ft", 1);
var pitch_deg = props.globals.getNode("orientation/pitch-deg", 1);
var roll_deg = props.globals.getNode("orientation/roll-deg", 1);
var roll_control = props.globals.getNode("controls/flight/aileron", 1);
var pitch_control = props.globals.getNode("controls/flight/elevator", 1);

# interior lighting and emissions -----------------------------------
var livery_cabin_surface = [	# A=ambient from livery, only updates upon livery change
				# _add= factor to calculate ambient from livery accounting for alert_level
				# E=calculated emissions
	{ AR: 0.800, AG: 0.800, AB: 0.800, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior8-grey", type:"", in_livery:1},
	{ AR: 0.588, AG: 0.529, AB: 0.529, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior1-console", type:"", in_livery:1},
	{ AR: 0.319, AG: 0.299, AB: 0.299, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior2-pillows", type:"", in_livery:1},
	{ AR: 0.350, AG: 0.350, AB: 0.350, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior3-detail", type:"", in_livery:1},
	{ AR: 0.600, AG: 0.600, AB: 0.600, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior4-floor", type:"", in_livery:1},
	{ AR: 0.500, AG: 0.500, AB: 0.500, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior5-base", type:"", in_livery:1},
	{ AR: 0.400, AG: 0.400, AB: 0.400, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior6-brace", type:"", in_livery:1},
	{ AR: 0.700, AG: 0.700, AB: 0.700, R_add: 0  , G_add: 0  , B_add: 0  , ER: 0, EG: 0, EB: 0, pname: "interior7-highlight", type:"", in_livery:1}
# Any ships parked in the landing bay as included models, can have their livery materials added here.
	];
var livery_cabin_count = size(livery_cabin_surface);
# 1 interior1-console
# 2 interior2-pillows
# 3 interior3-detail	also:	ceiling
# 4 interior4-floor
# 5 interior5-base		material-base
# 6 interior6-brace
# 7 interior7-highlight
# 0 interior8-grey		chair-pipe-interface

#==========================================================================
#    === define nasal non-local variables at startup ===
# -------- damage --------
var lose_altitude = 0;   # drift or sink when damaged or power shuts down
# ------ nav lights ------
var sun_angle = 0;  # down to 0 at high noon, 2 at midnight, depending on latitude
var visibility = 16000;                # 16Km
# --------- doors --------
var door_position = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
var door_triggered = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
var active_door = 0;
# -------- engines -------
var power_switch = 1;   # no request in-between. power goes direct to state.
var engine_request = 1;
var engine_level = 1;
var engine2_request = 1;
var engine2_level = 1;
var ftl3_request = 0;
var ftl3_level = 0;
var engine_state = 0;  # destination level for engine_level
var engine_drift = 0;
var ftl_state = 0;     # state = destination level
var ftl_drift = 0;
# ------- movement -------
airspeed_kt_Node.setValue(0);
abs_airspeed_Node.setValue(0);
var contact_altitude = 0;   # the altitude at which the model touches ground
var pitch_d = 0;
var airspeed = 0;
var asas = 0;
var engines_lvl = 0;
var hover_add = 0;              # increase in altitude to keep side bays and nose from touching ground
var hover_target_altitude = 0;  # ground_elevation + hover_ft (does not include hover_add)
var h_contact_target_alt = 0;   # adjusted for contact altitude
var skid_last_value = 0;
# --- ground detection ---
var init_agl = 5;     # some airports reported elevation change after movement begins
var ground_near = 1;  # instrument panel indicator lights
var ground_warning = 1;
# ----- maximum speed ----
maxspeed.setValue(500);
current.setValue(5);  # needed for engine-digital panel
var cpl = 5;          # current power level
var current_to = 5;   # distinguishes between change_maximum types. Current or To
var max_drift = 0;    # smoothen drift between maxspeed power levels
var max_lose = 0;     # loss of momentum after shutdown of engines
var max_from = 5;
var max_to = 5;
# -------- sounds --------
var sound_level = 0;
var sound_state = 0;
# ------- interior -------
var interior_lighting_base = 0;
var int_switch = 1;    # interior lights
var cockpit_locations = [ # x,y,z are starting positions, and are not on the same skew as the sim/view nodes.  x/y/z == aft/right/up
	{ x: -129.81 , y:  -1.08  , z: 46.851, h: 0  , p: 0, fov: 55, can_walk: 0, z_eye_offset: 1.129, last_x: -129.81 , last_y:   -1.08 , last_z: 46.851, last_h: 0 },
	{ x: -129.804, y:   0     , z: 47.074, h: 0  , p: 0, fov: 55, can_walk: 0, z_eye_offset: 1.129, last_x: -129.804, last_y:    0    , last_z: 47.074, last_h: 0 },
	{ x: -129.75 , y:   2.23  , z: 46.851, h: 0  , p: 0, fov: 55, can_walk: 1, z_eye_offset: 1.659, last_x: -129.75 , last_y:    2.23 , last_z: 46.851, last_h: 0 }, # walker position
	{ x: -313.9  , y:   1.903 , z: 15.611, h: 0  , p: 0, fov: 65, can_walk: 0, z_eye_offset: 1.659, last_x: -313.9  , last_y:    1.903, last_z: 15.611, last_h: 0 }, # nose
	{ x:   43.49 , y:  -82.32 , z:  6.100, h: 0  , p: 0, fov: 55, can_walk: 1, z_eye_offset: 1.659, last_x:   43.49 , last_y:  -82.32 , last_z:  6.100, last_h: 0 }, # port landing bay
	{ x:  -46.65 , y:  -93.50 , z: 19.55 , h: 180, p: 0, fov: 55, can_walk: 1, z_eye_offset: 1.659, last_x:  -46.65 , last_y:  -93.50 , last_z: 19.55 , last_h: 180 }, # port landing bay top catwalk
	{ x:  -61.1  , y:  106.86 , z:  6.100, h: 0  , p: 0, fov: 55, can_walk: 1, z_eye_offset: 1.659, last_x:  -61.1  , last_y:  106.86 , last_z:  6.100, last_h: 0 }, # starboard landing bay outside
	{ x:   45.27 , y:   89.25 , z: 18.033, h: 0  , p: 0, fov: 55, can_walk: 1, z_eye_offset: 1.659, last_x:   45.27 , last_y:   89.25 , last_z: 18.033, last_h: 0 }, # starboard landing bay catwalk
	{ x:  106.346, y:  -35.891, z: 64.02 , h: 197, p: 0, fov: 55, can_walk: 0, z_eye_offset: 1.659, last_x:  106.346, last_y:  -35.891, last_z: 64.02 , last_h: 197 } ];
	# x, y, z in meters
var hallway_locations = [
	{ can_walk: 0, x: 0 , y: 0 , z: 0 , h: 0 },
	{ can_walk: 0, x: 0 , y: 0 , z: 0 , h: 0 },
	{ can_walk: 1, x: -123.57 , y: 0.19 , z: 46.851 , h: 282 },
	{ can_walk: 0, x: 0 , y: 0 , z: 0 , h: 0 },
	{ can_walk: 2, x: 46.60 , y: -80.82 , z: 13.722 , h:   0 },
	{ can_walk: 1, x: 45.20 , y: -79.61 , z: 18.033 , h:  90 },
	{ can_walk: 2, x: 46.60 , y:  80.82 , z: 13.722 , h:   0 },
	{ can_walk: 1, x: 45.20 , y:  79.61 , z: 18.033 , h: 270 },
	{ can_walk: 0, x: 0 , y: 0 , z: 0 , h: 0 },
	# extra jump point to bridge
	{ can_walk: 0, x: 0 , y: 0 , z: 0 , h: 0 }, # filler (no jump point to position 0)
	{ can_walk: 0, x: 0 , y: 0 , z: 0 , h: 0 }, # filler (position 1)
	{ can_walk: 1, x: -121.10 , y: 6.13 , z: 46.851 , h: 12 } ];
var cockpitView = 0; # start at left side console
var hallway2_clear = 1;
# -------- dialog --------
var active_nav_button = [3, 3, 1];
var active_landing_button = [3, 1, 3];
var active_guide_button = [1, 3, 3];
var config_dialog = nil;
var livery_dialog = nil;

var reinit_daedalus = func {   # make it possible to reset the above variables
	lose_altitude = 0;
	contact_altitude = 0;
	power_switch = 1;
	engine_request = 1;
	engine_level = 1;
	engine2_request = 1;
	engine2_level = 1;
	ftl3_request = 0;
	ftl3_level = 0;
	antigrav.request = 0;
	engine_state = 0;
	engine_drift = 0;
	ftl_state = 0;
	ftl_drift = 0;
	pitch_d = 0;
	airspeed = 0;
	asas = 0;
	engines_lvl = 0;
	hover_add = 0;
	hover_target_altitude = 0;
	h_contact_target_alt = 0;
	skid_last_value = 0;
	init_agl = 5;
	cpl = 5;
	current_to = 5;
	max_drift = 0;
	max_lose = 0;
	max_from = 5;
	max_to = 5;
	sound_state = 0;
	int_switch = 1;
	cockpitView = 0;
	hallway2_clear = 1;
	cycle_cockpit(0);
	active_nav_button = [3, 3, 1];
	active_landing_button = [3, 1, 3];
	active_guide_button = [1, 3, 3];
	name = "daedalus-config";
	if (config_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		config_dialog = nil;
	}
}

 setlistener("sim/signals/reinit", func {
	reinit_daedalus();
 });

# door functions ----------------------------------------------------

var init_doors = func {
	foreach (var id_d; props.globals.getNode("sim/model/daedalus/doors").getChildren("door")) {
		append(doors, aircraft.door.new(id_d, 8.0));
	}
}
settimer(init_doors, 0);

var next_door = func { select_door(active_door + 1, 1) }

var previous_door = func { select_door(active_door - 1, 1) }

var select_door = func(sd_number, verbose) {
	active_door = sd_number;
	if (active_door < 0) {
		active_door = size(doors) - 1;
	} elsif (active_door >= size(doors)) {
		active_door = 0;
	}
	if (verbose) {
		gui.popupTip("Selecting " ~ doors[active_door].node.getNode("name").getValue());
	}
}

var baydoor_layout = { x1: 5.685, x2: 7.185, x3: 12.870, y1: 4.248, y2: 8.496, y3: 12.744, y4: 16.992, y5: 21.24 };

var baydoor_location = [
	{ x_offset: -125.40, y_offset: 0 }, # outer door Left
	{ x_offset: -125.40, y_offset: 0 }, # outer door Right
	{ x_offset: 29.13 , y_offset: -117.627 }, # Port/Left aft 01	origin=fore,left
	{ x_offset: 8.130 , y_offset: -117.627 }, # Port/Left center 02
	{ x_offset: -12.87, y_offset: -117.627 }, # Port/Left fore 03
	{ x_offset: -12.87, y_offset: 96.387 }, # Starboard/Right fore 04
	{ x_offset: 8.130 , y_offset: 96.387 }, # Starboard/Right center 05
	{ x_offset: 29.13 , y_offset: 96.387 } ]; # Starboard/Right aft 06

var check_baydoor_gap = func(door_number,x_pos,y_pos) {
	# returns: -1 = fore leaf , 1 = aft leaf , 2 = fore opening between leafs , 3 = aft opening , 0 = not on bay door
	var cbg_ret = 0;
	var x_center = baydoor_location[door_number].x_offset + (baydoor_layout.x3 * 0.5);
	# calculate moving line, instead of being precise with non-straight edge as described in baydoor_layout. MARK for improvement
	var x_open = ((door_position[door_number] - 0.1) < 0 ? 0 : clamp ((door_position[door_number] * 7.9888) - 0.79888, 0, (baydoor_layout.x3 * 0.5)));
	var x_fore_edge = x_center - x_open;
	var x_aft_edge = x_center + x_open;
	if (door_number >= 2) {
		if ((x_pos > baydoor_location[door_number].x_offset) and (x_pos <= x_fore_edge)) {
			cbg_ret = -1;
		} elsif ((x_pos > x_fore_edge) and (x_pos <= x_center)) {
			cbg_ret = 2;
		} elsif ((x_pos > x_center) and (x_pos < x_aft_edge)) {
			cbg_ret = 3;
		} elsif ((x_pos >= x_aft_edge) and (x_pos < baydoor_location[door_number].x_offset + baydoor_layout.x3)) {
			cbg_ret = 1;
		}
	}
	if (getprop("logging/walker-debug")) {
		print(sprintf("check_baydoor_gap(%1d %4.2f [%4.1f %4.1f %4.1f %4.1f %4.1f], %4.1f, %5.1f) = %2d",door_number,door_position[door_number],baydoor_location[door_number].x_offset,x_fore_edge,x_center,x_aft_edge,baydoor_location[door_number].x_offset + baydoor_layout.x3,x_pos,y_pos,cbg_ret));
	}
	return cbg_ret;
}

var door_update = func(door_number) {
	door_position[door_number] = getprop("sim/model/daedalus/doors/door["~door_number~"]/position-norm");
	hatch_lighting_update(door_number);
	# MARK for improvement: Could make this more complicated to get double bang of bottom bay doors, is not triggering at 0 currently.
	var trigger_location = [0.03, 0.07, 0, 0.01, 0.05, 2];
	var walker_changed = 0;
	if (door_number >=2 ) {
		trigger_location = [0.13, 0.17, 0.08, 0.12, 0.15, 1];
		# check walker location while in this if block
		var c_view = getprop("sim/current-view/view-number");
		if (c_view == 0) {
			var cpos = getprop("sim/model/daedalus/crew/cockpit-position");
			var from_x_position = getprop("sim/model/daedalus/crew/walker/x-offset-m");
			var new_y_position = getprop("sim/model/daedalus/crew/walker/y-offset-m");
			var new_zf_position = cockpit_locations[cpos].z;
			if (cpos == 4 and door_number >= 2 and door_number <= 4) {
				if (new_y_position < -96.37 and new_y_position > -117.65) {
					walker_changed = check_baydoor_gap(door_number, from_x_position, new_y_position);
				}
			} elsif (cpos == 6 and door_number >= 5 and door_number <= 7) {
				if (new_y_position > 96.949 and new_y_position < 118.23) {
					walker_changed = check_baydoor_gap(door_number, from_x_position, new_y_position);
				}
			}
			if (walker_changed) {	# within door boundary when door is moving
				if (walker_changed <= 1) {
					var slide_direction = (walker_changed >= 2 ? 0 : walker_changed);
					if (door_position[door_number] > 0) {
						new_zf_position = 6.11 - (clamp(door_position[door_number], 0, 0.1) * 5);
					}
					if ((door_number == walker_on_door.door_number) and (door_position[door_number] >= 0.1)) {
						walker_changed = ((door_position[door_number] - walker_on_door.last_position) * 7.190 * slide_direction);
					} else {
						walker_changed = 0;
					}
					walker_on_door.last_position = door_position[door_number];
					walker_on_door.door_number = door_number;
					var new_x_position = from_x_position + walker_changed;
					if (!(new_x_position > 42.0 or (new_x_position < 29.13 and new_x_position > 21.0) or (new_x_position < 8.13 and new_x_position > 0) or new_x_position < -12.87)) {
						xViewNode.setValue(new_x_position);
						yViewNode.setValue(new_y_position);
						zViewNode.setValue(new_zf_position + 1.659);
						setprop("sim/model/daedalus/crew/walker/x-offset-m", new_x_position);
						setprop("sim/model/daedalus/crew/walker/y-offset-m", new_y_position);
						setprop("sim/model/daedalus/crew/walker/z-offset-m", new_zf_position);
					}
				} else {
					if (walker_changed == 2) {
						walk.get_out(8);
					} elsif (walker_changed == 3) {
						walk.get_out(4);
					}
				}
			}
		}
	}
	# end walker update, back to bang sound triggering
	if (door_position[door_number] > trigger_location[0] and door_position[door_number] < trigger_location[1]) {
		door_triggered[door_number] = trigger_location[4];
	} elsif (door_position[door_number] > 0.93 and door_position[door_number] < 0.97) {
		door_triggered[door_number] = 0.95;
	}
	if (door_position[door_number] > trigger_location[2] and door_position[door_number] < trigger_location[3] and door_triggered[door_number] == trigger_location[4]) {
		setprop("sim/model/daedalus/doors/door["~door_number~"]/bang-trigger", 1);
		door_triggered[door_number] = 0.0;
		settimer(func { setprop("sim/model/daedalus/doors/door["~door_number~"]/bang-trigger", 0);}, trigger_location[5]);
	} elsif (door_position[door_number] > 0.99 and door_triggered[door_number] == 0.95) {
		setprop("sim/model/daedalus/doors/door["~door_number~"]/bang-trigger", 1);
		door_triggered[door_number] = 1.0;
		settimer(func { setprop("sim/model/daedalus/doors/door["~door_number~"]/bang-trigger", 0);}, 2);
	}
}

setlistener("sim/model/daedalus/doors/door[0]/position-norm", func {
	door_update(0);
});

setlistener("sim/model/daedalus/doors/door[1]/position-norm", func {
	door_update(1);
});

setlistener("sim/model/daedalus/doors/door[2]/position-norm", func {
	door_update(2);
});

setlistener("sim/model/daedalus/doors/door[3]/position-norm", func {
	door_update(3);
});

setlistener("sim/model/daedalus/doors/door[4]/position-norm", func {
	door_update(4);
});

setlistener("sim/model/daedalus/doors/door[5]/position-norm", func {
	door_update(5);
});

setlistener("sim/model/daedalus/doors/door[6]/position-norm", func {
	door_update(6);
});

setlistener("sim/model/daedalus/doors/door[7]/position-norm", func {
	door_update(7);
});

var toggle_door = func {
	doors[active_door].toggle();
}

# landing bay guide strobe lights -----------------------------------
var guide_light_check = func {
	var glc_i = !door_guide_direction * door_guide_on * power_switch;
	for (var i = 0 ; i <= 6 ; i += 1) {
		setprop("sim/model/daedalus/lighting/door[0]/bay-guide["~i~"]/state", glc_i);
		setprop("sim/model/daedalus/lighting/door[1]/bay-guide["~i~"]/state", glc_i);
	}
	if (!glc_i) {
		door_guide_position = -1;
	}
}

var door_guide_direction = -1; # -1 = out , 0 = no strobe , 1 = in
var guide_light_mode_Node = props.globals.getNode("sim/model/daedalus/lighting/guide-mode", 1);
setlistener("sim/model/daedalus/lighting/guide-mode", func {
	door_guide_direction = guide_light_mode_Node.getValue();
	active_guide_button = [ 3, 3, 3];
	if (door_guide_direction == -1) {
		active_guide_button[0]=1;
	} elsif (door_guide_direction == 1) {
		active_guide_button[2]=1;
	} else {
		active_guide_button[1]=1;
	}
	guide_light_check();
});

var door_guide_position = -1;
var door_guide_loop_id = 0;
var door_guide_on = 0;
setlistener("controls/lighting/baydoor-guide", func {
	door_guide_on = door_guide_switch_node.getValue();
	if (getprop("logging/guide-lighting-debug")) {
		print("listener:baydoor-guide ",door_guide_on);
	}
	guide_light_check();
});

var door_guide_switch_node = props.globals.getNode("controls/lighting/baydoor-guide", 1);
aircraft.light.new("sim/model/daedalus/lighting/guide", [0.25, 0.75], door_guide_switch_node);
setlistener("sim/model/daedalus/lighting/guide/state", func {
	var guide_state = getprop("sim/model/daedalus/lighting/guide/state");
	if (guide_state and (door_guide_direction != 0)) {
		if (door_guide_position == -1) {
			var strobe_sequencing = 0;
			if (door_position[0] >= 0.75) {
				door_guide_position = 0;
				if (door_guide_direction == -1) {
					door_guide_position = 6;
				}
				setprop("sim/model/daedalus/lighting/door[0]/bay-guide["~door_guide_position~"]/state", power_switch);
				strobe_sequencing = 1;
			}
			if (door_position[1] >= 0.75) {
				if (door_guide_position == -1) {
					door_guide_position = 0;
					if (door_guide_direction == -1) {
						door_guide_position = 6;
					}
				}
				setprop("sim/model/daedalus/lighting/door[1]/bay-guide["~door_guide_position~"]/state", power_switch);
				strobe_sequencing = 1;
			}
			if (getprop("logging/guide-lighting-debug")) {
				print(sprintf("listener:lighting/guide/state%2d [0]=%4.2f [1]=%4.2f sequencing=%1d dir=%2d dgpos=%3.1f",guide_state,door_position[0],door_position[1],strobe_sequencing,door_guide_direction,door_guide_position));
			}
			if (strobe_sequencing) {
				settimer(func { door_guide_loop(door_guide_loop_id += 1) }, 0.04);
				if (getprop("logging/guide-lighting-debug")) {
					print (" settimer door_guide_loop(",door_guide_loop_id,")");
				}
			}
		}
	} else {
		if (getprop("logging/guide-lighting-debug")) {
			print(sprintf("listener:lighting/guide/state%2d [0]=%4.2f [1]=%4.2f              dir=%2d dgpos=%3.1f",guide_state,door_position[0],door_position[1],door_guide_direction,door_guide_position));
		}
	}
});

var door_guide_update = func (door) {
	if (getprop("logging/guide-lighting-debug")) {
		print(sprintf("dgu(%4.1f)",door));
	}
	if (door_guide_direction) {
		door_guide_loop(door_guide_loop_id +=1);
	}
}

var door_guide_loop = func (id) {
	id == door_guide_loop_id or return;
	if (door_guide_position >= 0 and door_guide_position <= 6) {
		setprop("sim/model/daedalus/lighting/door[0]/bay-guide["~door_guide_position~"]/state", 0);
		setprop("sim/model/daedalus/lighting/door[1]/bay-guide["~door_guide_position~"]/state", 0);
	}
	door_guide_position += door_guide_direction;
	if (door_guide_position >=0 and door_guide_position <= 6) {
		var strobe_sequencing = 0;
		if (door_position[0] >= 0.75) {
			setprop("sim/model/daedalus/lighting/door[0]/bay-guide["~door_guide_position~"]/state", power_switch);
			strobe_sequencing = 1;
		}
		if (door_position[1] >= 0.75) {
			setprop("sim/model/daedalus/lighting/door[1]/bay-guide["~door_guide_position~"]/state", power_switch);
			strobe_sequencing = 1;
		}
		if (strobe_sequencing) {
			settimer(func { door_guide_loop(door_guide_loop_id +=1) }, 0.04);
		}
	} else {
		door_guide_position = -1;
	}
}

# give hatch sound effect one second to play ------------------------
var reset_trigger = func {
	setprop("sim/model/daedalus/sound/hatch-trigger", 0);
}

# systems -----------------------------------------------------------

setlistener("sim/model/daedalus/systems/power-switch", func {
	power_switch = getprop("sim/model/daedalus/systems/power-switch");
	interior_lighting_update();
});

setlistener("sim/model/daedalus/systems/engine-request", func {
	engine_request = getprop("sim/model/daedalus/systems/engine-request");
});

setlistener("sim/model/daedalus/systems/engine-level", func {
	engine_level = getprop("sim/model/daedalus/systems/engine-level");
});

setlistener("sim/model/daedalus/lighting/engine-glow", func {
	engines_lvl = getprop("sim/model/daedalus/lighting/engine-glow");
});

setlistener("sim/model/daedalus/systems/engine2-request", func {
	engine2_request = getprop("sim/model/daedalus/systems/engine2-request");
});

setlistener("sim/model/daedalus/systems/engine2-level", func {
	engine2_level = getprop("sim/model/daedalus/systems/engine2-level");
});

setlistener("sim/model/daedalus/systems/ftl3-request", func {
	ftl3_request = getprop("sim/model/daedalus/systems/ftl3-request");
});

# interior ----------------------------------------------------------

setlistener("sim/model/daedalus/lighting/interior-switch", func {
	int_switch = getprop("sim/model/daedalus/lighting/interior-switch");
	nav_lighting_update();
},, 0);

# lighting and texture ----------------------------------------------

setlistener("environment/visibility-m", func {
	visibility = getprop("environment/visibility-m");
}, 1, 0);

var emis_calc = 0.7;
setlistener("sim/model/daedalus/lighting/overhead/emission/factor", func {
	emis_calc = getprop("sim/model/daedalus/lighting/overhead/emission/factor");
}, 1, 0);
var amb_calc = 0.1;
setlistener("sim/model/daedalus/lighting/interior-ambient-factor", func {
	amb_calc = getprop("sim/model/daedalus/lighting/interior-ambient-factor");
}, 1, 0);

var set_ambient_I = func(i) {
	# emission calculation base
	var baseR = livery_cabin_surface[i].AR ;		# + (livery_cabin_surface[i].R_add * alert_level* int_switch * power_switch);
	livery_cabin_surface[i].ER = baseR;
	setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/amb-dif/red", baseR * amb_calc);
	var baseG = livery_cabin_surface[i].AG ;		# + (livery_cabin_surface[i].G_add * alert_level* int_switch * power_switch);
	livery_cabin_surface[i].EG = baseG;
	if (livery_cabin_surface[i].type == "GB") {
		setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/amb-dif/gb", baseG * amb_calc);
	} else {
		var baseB = livery_cabin_surface[i].AB ;	# + (livery_cabin_surface[i].B_add * alert_level* int_switch * power_switch);
		livery_cabin_surface[i].EB = baseB;
		setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/amb-dif/green", baseG * amb_calc);
		setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/amb-dif/blue", baseB * amb_calc);
	}
}

var recalc_material_I = func(i) {
	# calculate ambient base levels upon loading new livery
	livery_cabin_surface[i].R_add = clamp(livery_cabin_surface[i].AR * 1.5, 0.5, 1.0) - livery_cabin_surface[i].AR;  # tint calculation and amount to add when calculating alert_level
	livery_cabin_surface[i].G_add = clamp(livery_cabin_surface[i].AG * 0.75, 0, 1) - livery_cabin_surface[i].AG;
	if (livery_cabin_surface[i].type != "GB") {
		livery_cabin_surface[i].B_add = clamp(livery_cabin_surface[i].AB * 0.75, 0, 1) - livery_cabin_surface[i].AB;
	}
}

var hatch_interpolate = func (i_from, i_to, i_slider) {
	return ((i_to - i_from) * i_slider) + i_from;
}

var hatch_lighting_update = func (door) {
	if (door == 0 or door == 99) {
		var door0_D_factor = ((door_position[0] * 0.5) + 0.5) * amb_calc;
		setprop("sim/model/daedalus/lighting/door[0]/interior3-detail/amb-dif/red", livery_cabin_surface[3].AR * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior3-detail/amb-dif/green", livery_cabin_surface[3].AG * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior3-detail/amb-dif/blue", livery_cabin_surface[3].AB * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior4-floor/amb-dif/red", livery_cabin_surface[4].AR * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior4-floor/amb-dif/green", livery_cabin_surface[4].AG * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior4-floor/amb-dif/blue", livery_cabin_surface[4].AB * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior5-walls/amb-dif/red", livery_cabin_surface[5].AR * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior5-walls/amb-dif/green", livery_cabin_surface[5].AG * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior5-walls/amb-dif/blue", livery_cabin_surface[5].AB * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior6-brace/amb-dif/red", livery_cabin_surface[6].AR * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior6-brace/amb-dif/green", livery_cabin_surface[6].AG * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior6-brace/amb-dif/blue", livery_cabin_surface[6].AB * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior7-floor/amb-dif/red", livery_cabin_surface[7].AR * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior7-floor/amb-dif/green", livery_cabin_surface[7].AG * door0_D_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior7-floor/amb-dif/blue", livery_cabin_surface[7].AB * door0_D_factor);
		var door0_E_factor = 1 - (door_position[0] * 0.1);
		setprop("sim/model/daedalus/lighting/door[0]/interior3-detail/emission/red", getprop("sim/model/daedalus/lighting/interior3-detail/emission/red") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior3-detail/emission/green", getprop("sim/model/daedalus/lighting/interior3-detail/emission/green") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior3-detail/emission/blue", getprop("sim/model/daedalus/lighting/interior3-detail/emission/blue") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior4-floor/emission/red", getprop("sim/model/daedalus/lighting/interior4-floor/emission/red") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior4-floor/emission/green", getprop("sim/model/daedalus/lighting/interior4-floor/emission/green") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior4-floor/emission/blue", getprop("sim/model/daedalus/lighting/interior4-floor/emission/blue") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior5-walls/emission/red", getprop("sim/model/daedalus/lighting/interior5-base/emission/red") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior5-walls/emission/green", getprop("sim/model/daedalus/lighting/interior5-base/emission/green") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior5-walls/emission/blue", getprop("sim/model/daedalus/lighting/interior5-base/emission/blue") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior6-brace/emission/red", getprop("sim/model/daedalus/lighting/interior6-brace/emission/red") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior6-brace/emission/green", getprop("sim/model/daedalus/lighting/interior6-brace/emission/green") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior6-brace/emission/blue", getprop("sim/model/daedalus/lighting/interior6-brace/emission/blue") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior7-floor/emission/red", getprop("sim/model/daedalus/lighting/interior7-highlight/emission/red") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior7-floor/emission/green", getprop("sim/model/daedalus/lighting/interior7-highlight/emission/green") * door0_E_factor);
		setprop("sim/model/daedalus/lighting/door[0]/interior7-floor/emission/blue", getprop("sim/model/daedalus/lighting/interior7-highlight/emission/blue") * door0_E_factor);
	}
	if (door == 1 or door == 99) {
		var door1_D_factor = ((door_position[1] * 0.5) + 0.5) * amb_calc;
		setprop("sim/model/daedalus/lighting/door[1]/interior3-detail/amb-dif/red", livery_cabin_surface[3].AR * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior3-detail/amb-dif/green", livery_cabin_surface[3].AG * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior3-detail/amb-dif/blue", livery_cabin_surface[3].AB * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior4-floor/amb-dif/red", livery_cabin_surface[4].AR * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior4-floor/amb-dif/green", livery_cabin_surface[4].AG * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior4-floor/amb-dif/blue", livery_cabin_surface[4].AB * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior5-walls/amb-dif/red", livery_cabin_surface[5].AR * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior5-walls/amb-dif/green", livery_cabin_surface[5].AG * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior5-walls/amb-dif/blue", livery_cabin_surface[5].AB * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior6-brace/amb-dif/red", livery_cabin_surface[6].AR * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior6-brace/amb-dif/green", livery_cabin_surface[6].AG * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior6-brace/amb-dif/blue", livery_cabin_surface[6].AB * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior7-floor/amb-dif/red", livery_cabin_surface[7].AR * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior7-floor/amb-dif/green", livery_cabin_surface[7].AG * door1_D_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior7-floor/amb-dif/blue", livery_cabin_surface[7].AB * door1_D_factor);
		var door1_E_factor = 1 - (door_position[1] * 0.1);
		setprop("sim/model/daedalus/lighting/door[1]/interior3-detail/emission/red", getprop("sim/model/daedalus/lighting/interior3-detail/emission/red") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior3-detail/emission/green", getprop("sim/model/daedalus/lighting/interior3-detail/emission/green") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior3-detail/emission/blue", getprop("sim/model/daedalus/lighting/interior3-detail/emission/blue") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior4-floor/emission/red", getprop("sim/model/daedalus/lighting/interior4-floor/emission/red") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior4-floor/emission/green", getprop("sim/model/daedalus/lighting/interior4-floor/emission/green") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior4-floor/emission/blue", getprop("sim/model/daedalus/lighting/interior4-floor/emission/blue") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior5-walls/emission/red", getprop("sim/model/daedalus/lighting/interior5-base/emission/red") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior5-walls/emission/green", getprop("sim/model/daedalus/lighting/interior5-base/emission/green") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior5-walls/emission/blue", getprop("sim/model/daedalus/lighting/interior5-base/emission/blue") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior6-brace/emission/red", getprop("sim/model/daedalus/lighting/interior6-brace/emission/red") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior6-brace/emission/green", getprop("sim/model/daedalus/lighting/interior6-brace/emission/green") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior6-brace/emission/blue", getprop("sim/model/daedalus/lighting/interior6-brace/emission/blue") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior7-floor/emission/red", getprop("sim/model/daedalus/lighting/interior7-highlight/emission/red") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior7-floor/emission/green", getprop("sim/model/daedalus/lighting/interior7-highlight/emission/green") * door1_E_factor);
		setprop("sim/model/daedalus/lighting/door[1]/interior7-floor/emission/blue", getprop("sim/model/daedalus/lighting/interior7-highlight/emission/blue") * door1_E_factor);
	}
	if (door == 2 or door == 99) {
		var door2_opening = clamp(((door_position[2] - 0.1) * 1.404), 0, 1);
		setprop("sim/model/daedalus/lighting/door[2]/interior5-walls/emission/red", hatch_interpolate(0, (livery_cabin_surface[5].AR * interior_lighting_base), door2_opening));
		setprop("sim/model/daedalus/lighting/door[2]/interior5-walls/emission/green", hatch_interpolate(0, (livery_cabin_surface[5].AG * interior_lighting_base), door2_opening));
		setprop("sim/model/daedalus/lighting/door[2]/interior5-walls/emission/blue", hatch_interpolate(0, (livery_cabin_surface[5].AB * interior_lighting_base), door2_opening));
		setprop("sim/model/daedalus/lighting/door[2]/interior5-walls/amb-dif/red", hatch_interpolate((livery_cabin_surface[5].AR * interior_lighting_base * 0.25), livery_cabin_surface[5].AR, door2_opening));
		setprop("sim/model/daedalus/lighting/door[2]/interior5-walls/amb-dif/green", hatch_interpolate((livery_cabin_surface[5].AG * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door2_opening));
		setprop("sim/model/daedalus/lighting/door[2]/interior5-walls/amb-dif/blue", hatch_interpolate((livery_cabin_surface[5].AB * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door2_opening));
	}
	if (door == 3 or door == 99) {
		var door3_opening = clamp(((door_position[3] - 0.1) * 1.404), 0, 1);
		setprop("sim/model/daedalus/lighting/door[3]/interior5-walls/emission/red", hatch_interpolate(0, (livery_cabin_surface[5].AR * interior_lighting_base), door3_opening));
		setprop("sim/model/daedalus/lighting/door[3]/interior5-walls/emission/green", hatch_interpolate(0, (livery_cabin_surface[5].AG * interior_lighting_base), door3_opening));
		setprop("sim/model/daedalus/lighting/door[3]/interior5-walls/emission/blue", hatch_interpolate(0, (livery_cabin_surface[5].AB * interior_lighting_base), door3_opening));
		setprop("sim/model/daedalus/lighting/door[3]/interior5-walls/amb-dif/red", hatch_interpolate((livery_cabin_surface[5].AR * interior_lighting_base * 0.25), livery_cabin_surface[5].AR, door3_opening));
		setprop("sim/model/daedalus/lighting/door[3]/interior5-walls/amb-dif/green", hatch_interpolate((livery_cabin_surface[5].AG * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door3_opening));
		setprop("sim/model/daedalus/lighting/door[3]/interior5-walls/amb-dif/blue", hatch_interpolate((livery_cabin_surface[5].AB * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door3_opening));
	}
	if (door == 4 or door == 99) {
		var door4_opening = clamp(((door_position[4] - 0.1) * 1.404), 0, 1);
		setprop("sim/model/daedalus/lighting/door[4]/interior5-walls/emission/red", hatch_interpolate(0, (livery_cabin_surface[5].AR * interior_lighting_base), door4_opening));
		setprop("sim/model/daedalus/lighting/door[4]/interior5-walls/emission/green", hatch_interpolate(0, (livery_cabin_surface[5].AG * interior_lighting_base), door4_opening));
		setprop("sim/model/daedalus/lighting/door[4]/interior5-walls/emission/blue", hatch_interpolate(0, (livery_cabin_surface[5].AB * interior_lighting_base), door4_opening));
		setprop("sim/model/daedalus/lighting/door[4]/interior5-walls/amb-dif/red", hatch_interpolate((livery_cabin_surface[5].AR * interior_lighting_base * 0.25), livery_cabin_surface[5].AR, door4_opening));
		setprop("sim/model/daedalus/lighting/door[4]/interior5-walls/amb-dif/green", hatch_interpolate((livery_cabin_surface[5].AG * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door4_opening));
		setprop("sim/model/daedalus/lighting/door[4]/interior5-walls/amb-dif/blue", hatch_interpolate((livery_cabin_surface[5].AB * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door4_opening));
	}
	if (door == 5 or door == 99) {
		var door5_opening = clamp(((door_position[5] - 0.1) * 1.404), 0, 1);
		setprop("sim/model/daedalus/lighting/door[5]/interior5-walls/emission/red", hatch_interpolate(0, (livery_cabin_surface[5].AR * interior_lighting_base), door5_opening));
		setprop("sim/model/daedalus/lighting/door[5]/interior5-walls/emission/green", hatch_interpolate(0, (livery_cabin_surface[5].AG * interior_lighting_base), door5_opening));
		setprop("sim/model/daedalus/lighting/door[5]/interior5-walls/emission/blue", hatch_interpolate(0, (livery_cabin_surface[5].AB * interior_lighting_base), door5_opening));
		setprop("sim/model/daedalus/lighting/door[5]/interior5-walls/amb-dif/red", hatch_interpolate((livery_cabin_surface[5].AR * interior_lighting_base * 0.25), livery_cabin_surface[5].AR, door5_opening));
		setprop("sim/model/daedalus/lighting/door[5]/interior5-walls/amb-dif/green", hatch_interpolate((livery_cabin_surface[5].AG * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door5_opening));
		setprop("sim/model/daedalus/lighting/door[5]/interior5-walls/amb-dif/blue", hatch_interpolate((livery_cabin_surface[5].AB * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door5_opening));
	}
	if (door == 6 or door == 99) {
		var door6_opening = clamp(((door_position[6] - 0.1) * 1.404), 0, 1);
		setprop("sim/model/daedalus/lighting/door[6]/interior5-walls/emission/red", hatch_interpolate(0, (livery_cabin_surface[5].AR * interior_lighting_base), door6_opening));
		setprop("sim/model/daedalus/lighting/door[6]/interior5-walls/emission/green", hatch_interpolate(0, (livery_cabin_surface[5].AG * interior_lighting_base), door6_opening));
		setprop("sim/model/daedalus/lighting/door[6]/interior5-walls/emission/blue", hatch_interpolate(0, (livery_cabin_surface[5].AB * interior_lighting_base), door6_opening));
		setprop("sim/model/daedalus/lighting/door[6]/interior5-walls/amb-dif/red", hatch_interpolate((livery_cabin_surface[5].AR * interior_lighting_base * 0.25), livery_cabin_surface[5].AR, door6_opening));
		setprop("sim/model/daedalus/lighting/door[6]/interior5-walls/amb-dif/green", hatch_interpolate((livery_cabin_surface[5].AG * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door6_opening));
		setprop("sim/model/daedalus/lighting/door[6]/interior5-walls/amb-dif/blue", hatch_interpolate((livery_cabin_surface[5].AB * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door6_opening));
	}
	if (door == 7 or door == 99) {
		var door7_opening = clamp(((door_position[7] - 0.1) * 1.404), 0, 1);
		setprop("sim/model/daedalus/lighting/door[7]/interior5-walls/emission/red", hatch_interpolate(0, (livery_cabin_surface[5].AR * interior_lighting_base), door7_opening));
		setprop("sim/model/daedalus/lighting/door[7]/interior5-walls/emission/green", hatch_interpolate(0, (livery_cabin_surface[5].AG * interior_lighting_base), door7_opening));
		setprop("sim/model/daedalus/lighting/door[7]/interior5-walls/emission/blue", hatch_interpolate(0, (livery_cabin_surface[5].AB * interior_lighting_base), door7_opening));
		setprop("sim/model/daedalus/lighting/door[7]/interior5-walls/amb-dif/red", hatch_interpolate((livery_cabin_surface[5].AR * interior_lighting_base * 0.25), livery_cabin_surface[5].AR, door7_opening));
		setprop("sim/model/daedalus/lighting/door[7]/interior5-walls/amb-dif/green", hatch_interpolate((livery_cabin_surface[5].AG * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door7_opening));
		setprop("sim/model/daedalus/lighting/door[7]/interior5-walls/amb-dif/blue", hatch_interpolate((livery_cabin_surface[5].AB * interior_lighting_base * 0.25), livery_cabin_surface[5].AG, door7_opening));
	}
}

# update from livery ------------------------------------------------
setlistener("sim/model/livery/material/interior-console/ambient/red", func(n) {
	livery_cabin_surface[1].AR = getprop("sim/model/livery/material/interior-console/ambient/red");
	recalc_material_I(1);
	set_ambient_I(1);
},, 0);

setlistener("sim/model/livery/material/interior-console/ambient/green", func(n) {
	livery_cabin_surface[1].AG = getprop("sim/model/livery/material/interior-console/ambient/green");
	recalc_material_I(1);
	set_ambient_I(1);
},, 0);

setlistener("sim/model/livery/material/interior-console/ambient/blue", func(n) {
	livery_cabin_surface[1].AB = getprop("sim/model/livery/material/interior-console/ambient/blue");
	recalc_material_I(1);
	set_ambient_I(1);
},, 0);

setlistener("sim/model/livery/material/interior-pillows/ambient/red", func(n) {
	livery_cabin_surface[2].AR = getprop("sim/model/livery/material/interior-pillows/ambient/red");
	recalc_material_I(2);
	set_ambient_I(2);
},, 0);

setlistener("sim/model/livery/material/interior-pillows/ambient/green", func(n) {
	livery_cabin_surface[2].AG = getprop("sim/model/livery/material/interior-pillows/ambient/green");
	recalc_material_I(2);
	set_ambient_I(2);
},, 0);

setlistener("sim/model/livery/material/interior-pillows/ambient/blue", func(n) {
	livery_cabin_surface[2].AB = getprop("sim/model/livery/material/interior-pillows/ambient/blue");
	recalc_material_I(2);
	set_ambient_I(2);
},, 0);

setlistener("sim/model/livery/material/interior-detail/ambient/red", func(n) {
	livery_cabin_surface[3].AR = getprop("sim/model/livery/material/interior-detail/ambient/red");
	recalc_material_I(3);
	set_ambient_I(3);
},, 0);

setlistener("sim/model/livery/material/interior-detail/ambient/green", func(n) {
	livery_cabin_surface[3].AG = getprop("sim/model/livery/material/interior-detail/ambient/green");
	recalc_material_I(3);
	set_ambient_I(3);
},, 0);

setlistener("sim/model/livery/material/interior-detail/ambient/blue", func(n) {
	livery_cabin_surface[3].AB = getprop("sim/model/livery/material/interior-detail/ambient/blue");
	recalc_material_I(3);
	set_ambient_I(3);
},, 0);

setlistener("sim/model/livery/material/interior-floor/ambient/red", func(n) {
	livery_cabin_surface[4].AR = getprop("sim/model/livery/material/interior-floor/ambient/red");
	recalc_material_I(4);
	set_ambient_I(4);
},, 0);

setlistener("sim/model/livery/material/interior-floor/ambient/green", func(n) {
	livery_cabin_surface[4].AG = getprop("sim/model/livery/material/interior-floor/ambient/green");
	recalc_material_I(4);
	set_ambient_I(4);
},, 0);

setlistener("sim/model/livery/material/interior-floor/ambient/blue", func(n) {
	livery_cabin_surface[4].AB = getprop("sim/model/livery/material/interior-floor/ambient/blue");
	recalc_material_I(4);
	set_ambient_I(4);
},, 0);

setlistener("sim/model/livery/material/interior-base/ambient/red", func(n) {
	livery_cabin_surface[5].AR = getprop("sim/model/livery/material/interior-base/ambient/red");
	recalc_material_I(5);
	set_ambient_I(5);
},, 0);

setlistener("sim/model/livery/material/interior-base/ambient/green", func(n) {
	livery_cabin_surface[5].AG = getprop("sim/model/livery/material/interior-base/ambient/green");
	recalc_material_I(5);
	set_ambient_I(5);
},, 0);

setlistener("sim/model/livery/material/interior-base/ambient/blue", func(n) {
	livery_cabin_surface[5].AB = getprop("sim/model/livery/material/interior-base/ambient/blue");
	recalc_material_I(5);
	set_ambient_I(5);
},, 0);

setlistener("sim/model/livery/material/interior-brace/ambient/red", func(n) {
	livery_cabin_surface[6].AR = getprop("sim/model/livery/material/interior-brace/ambient/red");
	recalc_material_I(6);
	set_ambient_I(6);
},, 0);

setlistener("sim/model/livery/material/interior-brace/ambient/green", func(n) {
	livery_cabin_surface[6].AG = getprop("sim/model/livery/material/interior-brace/ambient/green");
	recalc_material_I(6);
	set_ambient_I(6);
},, 0);

setlistener("sim/model/livery/material/interior-brace/ambient/blue", func(n) {
	livery_cabin_surface[6].AB = getprop("sim/model/livery/material/interior-brace/ambient/blue");
	recalc_material_I(6);
	set_ambient_I(6);
},, 0);

setlistener("sim/model/livery/material/interior-highlight/ambient/red", func(n) {
	livery_cabin_surface[7].AR = getprop("sim/model/livery/material/interior-highlight/ambient/red");
	recalc_material_I(7);
	set_ambient_I(7);
},, 0);

setlistener("sim/model/livery/material/interior-highlight/ambient/green", func(n) {
	livery_cabin_surface[7].AG = getprop("sim/model/livery/material/interior-highlight/ambient/green");
	recalc_material_I(7);
	set_ambient_I(7);
},, 0);

setlistener("sim/model/livery/material/interior-highlight/ambient/blue", func(n) {
	livery_cabin_surface[7].AB = getprop("sim/model/livery/material/interior-highlight/ambient/blue");
	recalc_material_I(7);
	set_ambient_I(7);
},, 0);

setlistener("sim/model/livery/material/interior-chair-pipe/ambient/red", func(n) {
	livery_cabin_surface[0].AR = getprop("sim/model/livery/material/interior-chair-pipe/ambient/red");
	recalc_material_I(0);
	set_ambient_I(0);
},, 0);

setlistener("sim/model/livery/material/interior-chair-pipe/ambient/green", func(n) {
	livery_cabin_surface[0].AG = getprop("sim/model/livery/material/interior-chair-pipe/ambient/green");
	recalc_material_I(0);
	set_ambient_I(0);
},, 0);

setlistener("sim/model/livery/material/interior-chair-pipe/ambient/blue", func(n) {
	livery_cabin_surface[0].AB = getprop("sim/model/livery/material/interior-chair-pipe/ambient/blue");
	recalc_material_I(0);
	set_ambient_I(0);
},, 0);

#==========================================================================
# loop function #2 called by interior_lighting_loop every 3 seconds
#    or every 0.25 when time warp

var interior_lighting_update = func {
	var intli = 0;    # calculate brightness of interior lighting as sun goes down
	sun_angle = getprop("sim/time/sun-angle-rad");  # Tied property, cannot listen
	if (power_switch) {
		if (int_switch) {
			intli = emis_calc;	# maximum emission always 0.7 at night
		}
		setprop("sim/model/daedalus/lighting/overhead/emission/red", int_switch);
		setprop("sim/model/daedalus/lighting/overhead/emission/gb", int_switch);
		setprop("sim/model/daedalus/lighting/waldo/emission/red", int_switch * 0.8);
		setprop("sim/model/daedalus/lighting/waldo/emission/gb", int_switch * 0.8);
	} else {
		setprop("sim/model/daedalus/lighting/overhead/emission/red", 0);
		setprop("sim/model/daedalus/lighting/overhead/emission/gb", 0);
		setprop("sim/model/daedalus/lighting/waldo/emission/red", 0);
		setprop("sim/model/daedalus/lighting/waldo/emission/gb", 0);
	}
	for (var i = 0; i < livery_cabin_count; i += 1) {
		set_ambient_I(i);  # calculate and set ambient levels
	}
	# next calculate emissions for night lighting
	for (var i = 0; i < livery_cabin_count; i += 1) {
		setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/emission/red", livery_cabin_surface[i].ER * intli);
		
	}
	for (var i = 0; i < livery_cabin_count; i += 1) {
		if (livery_cabin_surface[i].type == "GB") {
			setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/emission/gb", livery_cabin_surface[i].EG * intli);
		} else {
			setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/emission/green", livery_cabin_surface[i].EG * intli);
			setprop("sim/model/daedalus/lighting/"~livery_cabin_surface[i].pname~"/emission/blue", livery_cabin_surface[i].EB * intli);
		}
	}
	setprop("sim/model/daedalus/lighting/interior-specular", (0.5 - (0.5 * int_switch)));

	hatch_lighting_update(99);
}

var interior_lighting_loop = func {
	interior_lighting_update();
	if (getprop("sim/time/warp-delta")) {
		settimer(interior_lighting_loop, 0.25);
	} else {
		settimer(interior_lighting_loop, 3);
	}
}

#==========================================================================
# loop function #3 called by nav_light_loop every 3 seconds
#    or every 0.5 seconds when time warp ============================

var nav_lighting_update = func {
	var nlu_nav = nav_light_switch.getValue();
	sun_angle = getprop("sim/time/sun-angle-rad");  # Tied property, cannot listen
	if (nlu_nav == 2) {
		nav_lights_state.setBoolValue(1);
	} else {
		if (nlu_nav == 1) {
			nav_lights_state.setBoolValue(visibility < 5000 or sun_angle > 1.4);
		} else {
			nav_lights_state.setBoolValue(0);
		}
	}
}

var nav_light_loop = func {
	nav_lighting_update();
	if (getprop("sim/time/warp-delta")) {
		settimer(nav_light_loop, 0.5);
	} else {
		settimer(nav_light_loop, 3);
	}
}

#==========================================================================

var change_maximum = func(cm_from, cm_to, cm_type) {
	var lmt = limit[(engine_level + (engine2_level* 2) + (ftl3_level* 4))];
	if (lmt < 0) {
		lmt = 0;
	}
	if (cm_to < 0) {  # shutdown by crash
		cm_to = 0;
	}
	if (max_drift) {   # did not finish last request yet
		if (cm_to > cm_from) {
			if (cm_type < 2) {  # startup from power down. bring systems back online
				cm_to = max_to + 1;
			}
		} else {
			var cm_to_new = max_to - 1;
			if (cm_to_new < 0) {  # midair shutdown
				cm_to_new = 0;
			}
			cm_to = cm_to_new;
		}
		if (cm_to >= size(speed_mps)) { 
			cm_to = size(speed_mps) - 1;
		}
		if (cm_to >= lmt) {
			cm_to = lmt;
		}
		if (cm_to < 0) {
			cm_to = 0;
		}
	} else {
		max_from = cm_from;
	}
	max_to = cm_to;
	max_drift = abs(speed_mps[cm_from] - speed_mps[cm_to]) / 20;
	if (cm_type > 1) {
		# separate new maximum from limit. by engine shutdown/startup
		current_to = cpl;
	} else {
		# by joystick flaps request
		current_to = cm_to;
	}
}

# modify flaps to change maximum speed --------------------------

controls.flapsDown = func(fd_d) {  # 1 decrease speed gearing -1 increases by default
	var fd_return = 0;
	if(power_switch) {
		if (!fd_d) {
			return;
		} elsif (fd_d > 0 and cpl > 0) {    # reverse joystick buttons direction by exchanging < for >
			change_maximum(cpl, (cpl-1), 1);
			fd_return = 1;
		} elsif (fd_d < 0 and cpl < size(speed_mps) - 1) {    # reverse joystick buttons direction by exchanging < for >
			var check_max = cpl;
			if (max_drift > 0) {
				check_max = max_to;
			}
			if (cpl >= limit[(engine_level + (engine2_level* 2) + (ftl3_level* 4))]) {
				if (engine_level) {
					if (engine2_level) {
						popupTip2("Unable to comply. Orbital velocities requires higher energy setting");
					} else {
						popupTip2("Unable to comply. Requested velocity requires 2nd engines to be online");
					}
				} else {
					popupTip2("Unable to comply. Atmospheric engines are OFF LINE");
				}
			} elsif (check_max > 6 and contact_altitude < 15000) {
				popupTip2("Unable to comply below 15,000 ft.");
			} elsif (check_max > 7 and contact_altitude < 50000) {
				popupTip2("Unable to comply below 50,000 ft.");
			} elsif (check_max > 8 and contact_altitude < 328000) {
				popupTip2("Unable to comply below 328,000 ft. (100 Km) The boundary between atmosphere and space.");
			} elsif (check_max > 9 and contact_altitude < 792000) {
				popupTip2("Unable to comply below 792,000 ft. (150 Miles) The NASA defined boundary for space.");
			} else {
				change_maximum(cpl, (cpl + 1), 1);
				fd_return = 1;
			}
		}
		if (fd_return) {
			var ss = speed_mps[max_to];
			popupTip2("Max. Speed " ~ ss ~ " m/s");
		}
		current.setValue(cpl);
	} else {
		popupTip2("Unable to comply. Main power is off.");
	}
}


# position adjustment function =====================================

var settle_to_level = func {
	var hg_roll = roll_deg.getValue() * 0.75;
	roll_deg.setValue(hg_roll);  # unless on hill... doesn't work right with ufo model
	var hg_roll = roll_control.getValue() * 0.75;
	roll_control.setValue(hg_roll);
	var hg_pitch = pitch_deg.getValue() * 0.75;
	pitch_deg.setValue(hg_pitch);
	var hg_pitch = pitch_control.getValue() * 0.75;
	pitch_control.setValue(hg_pitch);
}

var hover_atan = func(d,x) {
	var a = d * math.pi / 180;
	var y = abs(math.sin(a) / math.cos(a)) * x;
	var h = ((d < 90) ? (abs(x / math.cos(a))) : 0);
	var r = (x / h * y);
	return ((r < x) ? r : x);
}

#==========================================================================
# -------- MAIN LOOP called by itself every cycle --------

var update_main = func {
	var skid_altitude_change = 0;

	var gnd_elev = ground_elevation_ft.getValue();  # ground elevation
	var altitude = altitude_ft_Node.getValue();  # aircraft altitude

	if (gnd_elev == nil) {    # startup check
		gnd_elev = 0;
	}
	if (altitude == nil) {
		altitude = -9999;
	}
	if (altitude > -9990) {   # wait until program has started
		pitch_d = pitch_deg.getValue();   # update variables used by everybody
		airspeed = airspeed_kt_Node.getValue();
		asas = abs(airspeed);
		abs_airspeed_Node.setDoubleValue(asas);
		 # ----- initialization checks -----
		if (init_agl > 0) { 
			 # trigger rumble sound to be on
			setprop("controls/engines/engine/throttle",0.01);
			 # find real ground level
			altitude = gnd_elev + init_agl;
			altitude_ft_Node.setDoubleValue(altitude);
			if (init_agl > 1) {
				init_agl -= 0.75;
			} elsif (init_agl > 0.25) {
				init_agl -= 0.25;
			} else {
				init_agl -= 0.05;
			}
			if (init_agl <= 0) {
				setprop("controls/engines/engine/throttle",0);
			}
		}
		var hover_ft = 0;
		contact_altitude = altitude - 5.1 - hover_add;   # adjust calculated altitude for bay/nose dip
		# ----- only check hover if near ground ------------------
		var new_ground_near = 0;   # see if indicator lights can be turned off
		var new_ground_warning = 0;
		var check_agl = (asas * 0.05) + 550;
		if (check_agl < 600) {
			check_agl = 600;
		}
		if (contact_altitude < (gnd_elev + check_agl)) {
			new_ground_near = 1;
			var roll_d = abs(roll_deg.getValue());
			var skid_w2 = 0;
			var skid_altitude_change = 0;
			if (pitch_d > 0) {
				# keep tail from touching ground
				hover_add = hover_atan(pitch_d, 522.214);
			} else {
				# keep nose from touching ground
				hover_add = hover_atan(pitch_d, 1033.809);
			}
			# keep side bays from touching ground
			var rolld = hover_atan(roll_d, 489.271);
			hover_add = hover_add + rolld;   # total clearance for model above gnd_elev
				# add to hover the airspeed calculation to increase ground separation with airspeed
			if (asas < 100) {  # near ground hovering altitude calculation
				hover_ft = 2.3 + (0.022 * (asas - 100));
			} elsif (asas > 500) {  # increase separation from ground
				hover_ft = 22.3 + ((asas - 500) * 0.023);
			} else {    # hold altitude above ground, increasing with velocity
				hover_ft = (asas * 0.05) - 2.7;
			}
			if (engines_lvl < 1.0) {
				hover_ft = (hover_ft * engines_lvl);  # smoothen assent on startup
			}

			if (gnd_elev < 0) {   
				# likely over ocean water
				gnd_elev = 0;  # keep above water until there is an ocean bottom
			}
			contact_altitude = altitude - 5.1 - hover_add;   # update with newer hover amounts
			hover_target_altitude = gnd_elev + 5.1 + hover_add + hover_ft;  # hover elevation
			h_contact_target_alt = gnd_elev + hover_ft;

			if (contact_altitude < h_contact_target_alt) {
				 # below ground/flight level
				if (altitude > 0) {            # check for skid, smoothen sound effects
					if (contact_altitude < gnd_elev) {
						skid_w2 = (gnd_elev - contact_altitude);  # depth
						if (skid_w2 < skid_last_value) {  # abrupt impact or
							 # below ground, contact should skid
							skid_w2 = (skid_w2 + skid_last_value) * 0.75; # smoothen ascent
						 }
					}
				}
				skid_altitude_change = hover_target_altitude - altitude;
				if (skid_altitude_change > 0.5) {
					new_ground_warning = 1;
					if (skid_altitude_change < hover_ft) {
						# hover increasing altitude, but still above ground
						# add just enough skid to create the sound of 
						# emergency anti-grav and thruster action
						if (skid_w2 < 1.0) {
							skid_w2 = 1.0;
						}
					}
					if (skid_altitude_change > skid_w2) {
						 # keep skid sound going and dig in if bounding up large hill
						var impact_factor = (skid_altitude_change / asas * 25);
						 # vulnerability to impact. Increasing from 25 increases vulnerability
						if (skid_altitude_change > impact_factor) {  # but not if on flat ground
							new_ground_warning = 2;
							skid_w2 = skid_altitude_change;  # choose the larger skid value
						}
					}
				}
				if (hover_ft < 0) {  # separate skid effects from actual impact
					altitude = hover_target_altitude - hover_ft;
				} else {
					altitude = hover_target_altitude;
				}
				altitude_ft_Node.setDoubleValue(altitude);  # force above ground elev to hover elevation at contact
				contact_altitude = altitude - 5.1 - hover_add;
				if (pitch_d > 0 or pitch_d < -0.5) {
					 # If aircraft hits ground, then nose/tail gets thrown up
					if (asas > 500) {  # new pitch adjusted for airspeed
						var airspeed_pch = 0.2;  # rough ride
					} else {
						var airspeed_pch = asas / 500 * 0.2;
					}
					if (airspeed > 0.1) {
						if (pitch_d > 0) {
							# going uphill
							pitch_d = pitch_d * (1.0 + airspeed_pch);
							pitch_deg.setDoubleValue(pitch_d);
						} else {
							# nose down
							pitch_d = pitch_d * (1.0 - airspeed_pch);
							pitch_deg.setDoubleValue(pitch_d);
						}
					} elsif (airspeed < -0.1) {    # reverse direction
						if (pitch_d < 0) {  # uphill
							pitch_d = pitch_d * (1.0 + airspeed_pch);
							pitch_deg.setDoubleValue(pitch_d);
						} else {
							pitch_d = pitch_d * (1.0 - airspeed_pch);
							pitch_deg.setDoubleValue(pitch_d);
						}
					}
				}
			} else {
				# smoothen to zero
				var skid_w2 = (skid_last_value) / 2;
			}
			if (skid_w2 < 0.001) {
				skid_w2 = 0;
			}
			var skid_w_vol = skid_w2 * 0.1;  # factor for volume usage
			if (skid_w_vol > 1.0) {
				skid_w_vol = 1.0;
			}
			if (skid_altitude_change < 5) {
				if (abs(pitch_d) < 3.75) {
					skid_w_vol = skid_w_vol * (abs(pitch_d + 0.25)) * 0.25;
				}
			}
			setprop("sim/model/daedalus/position/skid-wow", skid_w_vol);
			skid_last_value = skid_w2;
		} else {
			# not near ground, skipping hover
			setprop("sim/model/daedalus/position/skid-wow", 0);
			skid_last_value = 0;
			hover_add = 0;
			h_contact_target_alt = 0;
		}
		# update instrument warning lights if changed
		if (new_ground_near != ground_near) {
			if (new_ground_near) {
				setprop("sim/model/daedalus/lighting/ground-near", 1);
			} else {
				setprop("sim/model/daedalus/lighting/ground-near", 0);
			}
			ground_near = new_ground_near;
		}
		if (new_ground_warning != ground_warning) {
			setprop("sim/model/daedalus/lighting/ground-warning", new_ground_warning);
			ground_warning = new_ground_warning;
		}

		# ----- lose altitude -----
		if (engines_lvl < 0.2 or power_switch == 0) {
			if ((contact_altitude - 0.0001) < h_contact_target_alt) {
				# already on/near ground
				if (lose_altitude > 0.2) {
					lose_altitude = 0.2;  # avoid bouncing by simulating gravity
				}
				if (!antigrav.request) {
					if (!engine_request) {
						settle_to_level();
					}
				} else {
					lose_altitude = 0;
				}
			} else {
				# not on/near ground
				if (!(engine2_level and asas > 150)) {
					# ftl power is off and not fast enough to fly without engines on-line
					lose_altitude += 0.01;
	# need to adjust terminal velocity based on pitch and add actual physics
					if (lose_altitude > 17) {
						# maximum at terminal velocity with nose down unpowered estimated: 1026ft/sec
						lose_altitude = 17;
					}
					if ((contact_altitude - h_contact_target_alt) < 3) {   # really close to ground but not below it
						if (!engine_request) {
							settle_to_level();
						}
					}
				} else { # fast enough to fly without anti-grav
					lose_altitude = lose_altitude * 0.5;
					if (lose_altitude < 0.001) {
						lose_altitude = 0; 
					}
				}
			}
			if (lose_altitude > 0) {
				up(-1, lose_altitude, 0);
			}
		} else {
			lose_altitude = 0;
		}

		# ----- also calculate altitude-agl since ufo model doesn't -----
		var aa = altitude - gnd_elev;
		setprop("sim/model/daedalus/position/shadow-alt-agl-ft", aa);
		var agl = contact_altitude - gnd_elev + hover_add;
		setprop("sim/model/daedalus/position/altitude-agl-ft", agl);

		# ----- handle traveling backwards and update movement variables ------
		#       including updating sound based on airspeed
		# === speed up or slow down from engine level ===
		var max = maxspeed.getValue();
		if (!power_switch) { 
			if (engine2_request) {   # deny ftl drive request
				setprop("sim/model/daedalus/systems/engine2-request", 0);
				engine2_request = 0;
			}
			if (ftl3_request) {
				setprop("sim/model/daedalus/systems/ftl3-request", 0);
				ftl3_request = 0;
			}
		}
		if (cpl > 6) {
			if (cpl > 10 and contact_altitude < 792000 and max_to > 10) {
				popupTip2("Approaching planet. Reducing speed");
				change_maximum(cpl, 10, 1); 
			} elsif (cpl > 9 and contact_altitude < 328000 and max_to > 9) {
				popupTip2("Entering upper atmosphere. Reducing speed");
				change_maximum(cpl, 9, 1); 
			} elsif (cpl > 8 and contact_altitude < 50000 and max_to > 8) {
				popupTip2("Entering lower atmosphere. Reducing speed");
				change_maximum(cpl, 8, 1); 
			} elsif (cpl > 7 and contact_altitude < 15000 and max_to > 7) {
				popupTip2("Entering lower atmosphere. Reducing speed");
				change_maximum(cpl, 7, 1); 
			}
		}
		if (!power_switch) {
			change_maximum(cpl, 0, 2);
			if (engine2_level) {
				setprop("sim/model/daedalus/systems/engine2-level", 0);
			}
			if (ftl3_level) {
				ftl3_level = 0;
			}
			if (agl > 10) {   # not in ground contact, glide
				max_lose = max_lose + (0.005 * abs(pitch_d));
			} else {     # rapid deceleration
				max_lose = (asas < 80 ? (asas > 20 ? 16 : ((100 - asas) * asas * 0.01)) : (asas * 0.2));
			}
	# need to import acceleration physics calculations from walker
			if (max_lose > 10) {  # don't decelerate too quickly
				if (agl > 10) {
					max_lose = 10;
				} else {
					if (max_lose > 75) {
						max_lose = 75;
					}
				}
			}
			if (asas < 5) {  # already stopped
				maxspeed.setDoubleValue(0);
				setprop("controls/engines/engine/throttle", 0.0);
			}
			max_drift = max_lose;
		} else {  # power is on
			if (engine_request != engine_level) {
				change_maximum(cpl, limit[(engine_request + (engine2_level * 2) + (ftl3_level * 4))], 2);
				setprop("sim/model/daedalus/systems/engine-level", engine_request);
			}
			if (engine2_request != engine2_level) {
				change_maximum(cpl, limit[(engine_level + (engine2_request * 2) + (ftl3_level * 4))], 2);
				setprop("sim/model/daedalus/systems/engine2-level", engine2_request);
			}
			if (ftl3_request != ftl3_level) {
				change_maximum(cpl, limit[(engine_level + (engine2_level * 2) + (ftl3_request * 4))], 2);
				ftl3_level = ftl3_request;
				setprop("sim/model/daedalus/systems/ftl3-level", ftl3_level);
			}
		}
		if (max > 1 and max_to < max_from) {      # decelerate smoothly
			max -= (max_drift / 2);
			if (max <= speed_mps[max_to]) {     # destination reached
				cpl = max_to;
				max_from = max_to;
				max = speed_mps[max_to];
				max_drift = 0;
				max_lose = 0;
				if (!power_switch) {       # override if no power
					max = 1;
				}
			}
			maxspeed.setDoubleValue(max);
		}
		if (max_to > max_from) {         # accelerate
			if (current_to == max_to) {   # normal request to change power-maxspeed
				max += max_drift;
				if (max >= speed_mps[max_to]) { 
					# destination reached
					cpl = max_to;
					max_from = max_to;
					max = speed_mps[max_to];
					max_drift = 0;
					max_lose = 0;
				}
				maxspeed.setDoubleValue(max);
			} else {    # only change maximum, as when turning on an engine
				max_from = max_to;
				max_drift = 0;
				max_lose = 0;
				if (cpl == 0 and current_to == 0) {     # turned on power from a complete shutdown
					maxspeed.setDoubleValue(speed_mps[2]);
					current_to = max_to;
					cpl = 2;
				}
			}
		}
		current.setValue(cpl);

		# === sound section based on position/airspeed/altitude ===
		var slv = sound_level;
		if (power_switch) {
			if (engine_drift < 1 and slv > 1) {  # shutdown reactor before timer shutdown of standby power
				slv = 0.99;
			}
			if (asas < 1 and agl < 2 and !antigrav.request) {
				if (sound_state and slv > 0.999) {  # shutdown request by landing has 2.5 sec delay
					slv = 2.5;
				}
				sound_state = 0;
			} else {
				if (((engine_state < engine_drift) or (!engine_state)) and asas < 5 and !antigrav.request) {  # antigrav shutdown
					sound_state = 0;
					antigrav.request = 0;
					if (antigrav.momentum_watch) {
						antigrav.up_factor = 0;
						antigrav.momentum_watch -= 1;
					}
					if (slv >= 1) {
						slv = 0.99;
					}
				} else {
					if (asas > 5 or agl >= 2 or antigrav.request) {
						sound_state = 1;
					} else {
						sound_state = 0;
					}
				}
			}
		} else {
			if (sound_state) {  # power shutdown with reactor on. single entry.
				slv = 0.99;
				sound_state = 0;
				antigrav.request = 0;
			}
		}
		if (sound_state != slv) {  # ramp up reactor sound fast or down slow
			if (sound_state) { 
				slv += 0.02;
			} else {
				slv -= 0.00625;
			}
			if (sound_state and slv > 1.0) {  # bounds check
				slv = 1.000;
				antigrav.request = 0;
			}
			if (slv > 0.5 and antigrav.request) {
				if (antigrav.request <= 1) {
					antigrav.request -= 0.025;  # reached sufficient power to turn off trigger
					slv -= 0.02;  # hold this level for a couple seconds until either another
					 # keyboard/joystick request confirms startup, or time expires and shutdown
					if (antigrav.request < 0.1) {
						antigrav.request = 0;  # holding time expired
					}
				}
			}
			if (slv < 0.0) {
				slv = 0.000;
			}
			sound_level = slv;
		}
		# engine rumble sound
		if (asas < 200) {
			var a1 = 0.3 + (asas * 0.001);
		} elsif (asas < 4000) {
			var a1 = 0.5 + ((asas - 200) * 0.0001315);
		} else {
			var a1 = 1.0;
		}
		var a3 = (asas * 0.0000625) + 0.5;	# 4000 kts = 0.25 pitch
		if (a3 > 0.75) {
			a3 = ((asas - 4000) / 384000) + 0.75;
		}
		if (slv > 1.0) {    # timer to shutdown
			var a2 = a1;
			var a5 = (asas * 0.0002) + 0.2;
			var a6 = 1;
		} else {      # shutdown progressing
			var a2 = a1 * slv;
			a3 = a3 * slv;
			var a5 = slv * ((asas * 0.0002) + 0.2);
			var a6 = slv;
		}
		if (a5 > 4.5) {
			a5 = 4.5;
		}
		if (engine2_level) {
			setprop("sim/model/daedalus/lighting/forward-glow", a5);
			if (asas > 1 or slv == 1.0 or slv > 2.0) {
				ftl_state = (asas * 0.0004) + 0.2;
			} elsif (slv > 1.6) {
				ftl_state = ((slv * 3) - 5) * ((asas * 0.0004) + 0.2);
			} else {
				ftl_state = 0;
			}
		} else {
			setprop("sim/model/daedalus/lighting/forward-glow", 0);
			ftl_state = 0;
		}
		if (engine_level) {
			engine_state = a6;
		} else {
			engine_state = 0;
		}
		if (power_switch) {
			if (engine_state > engine_drift) {
				engine_drift += 0.04;
				if (engine_drift > engine_state) {
					engine_drift = engine_state;
				}
			} elsif (engine_state < engine_drift) {
				if (engine_level) {
					engine_drift = engine_state;
				} else {
					engine_drift -= 0.02;
				}
			}
		} else {
			engine_drift -= 0.02;
		}
		if (engine_drift < 0) {  # bounds check
			engine_drift = 0;
		}
		if (ftl_state > ftl_drift) {
			ftl_drift += 0.1;
			if (ftl_drift > ftl_state) {
				ftl_drift = ftl_state;
			}
		} elsif (ftl_state < ftl_drift) {
			if (engine2_level) {
				ftl_drift -= 0.1;
			} else {
				ftl_drift -= 0.02;
			}
			if (ftl_drift < ftl_state) {
				ftl_drift = ftl_state;
			}
		}
		var a4 = (ftl_drift - 1.75) * 0.2;
		if (!engine_level and !engine2_level) {
			a2 = a2 / 2;
		}
		if (a3 > 12.5) {  # set upper limits
			a3 = 12.5;
		}
		a4 = clamp(a4,0,1.0);
		setprop("sim/model/daedalus/sound/engines-volume-level", a2);
		setprop("sim/model/daedalus/sound/pitch-level", a3);
		setprop("sim/model/daedalus/lighting/engine-glow", engine_drift);
		if (engine_level) {
			if (!engine_drift and !power_switch and !slv) {
				setprop("sim/model/daedalus/systems/engine-level", 0);
			}
		}
		setprop("sim/model/daedalus/lighting/ftl-glow", a4);
	}
	settimer(update_main, 0);
}

# VTOL anti-grav functions ---------------------------------------

controls.elevatorTrim = func(et_d) {
	if (!et_d) {
		return;
	} else {
		antigrav.input_type = 2;
		var js1pitch = abs(joystick_elevator.getValue());
		up((et_d < 0 ? -1 : 1), js1pitch, 2);
	}
}

var reset_landing = func {
	setprop("sim/model/daedalus/position/landing-wow", 0);
}

setlistener("sim/model/daedalus/position/landing-wow", func {
	if (getprop("sim/model/daedalus/position/landing-wow")) {
		settimer(reset_landing, 0.4);
		if (antigrav.momentum) {
			antigrav.up_factor = 0;
			antigrav.momentum_watch -= 1;
			antigrav.momentum = 0;
		}
	}
 });

var reset_squeal = func {
	setprop("sim/model/daedalus/position/squeal-wow", 0);
}

setlistener("sim/model/daedalus/position/squeal-wow", func {
	if (getprop("sim/model/daedalus/position/squeal-wow")) {
		settimer(reset_squeal, 0.3);
	}
 });

# mouse hover -------------------------------------------------------
#var KbdShift = props.globals.getNode("/devices/status/keyboard/shift");
#var KbdCtrl = props.globals.getNode("/devices/status/keyboard/ctrl");
var mouse = { savex: nil, savey: nil };
setlistener("/sim/startup/xsize", func(n) mouse.centerx = int(n.getValue() / 2), 1);
setlistener("/sim/startup/ysize", func(n) mouse.centery = int(n.getValue() / 2), 1);
setlistener("/sim/mouse/hide-cursor", func(n) mouse.hide = n.getValue(), 1);
#setlistener("/devices/status/mice/mouse/x", func(n) mouse.x = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/y", func(n) mouse.y = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/mode", func(n) mouse.mode = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/button[0]", func(n) mouse.lmb = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/button[1]", func(n) {
	mouse.mmb = n.getValue();
	if (mouse.mode)
		return;
	if (mouse.mmb) {
		controls.centerFlightControls();
#		mouse.savex = mouse.x;
		mouse.savey = mouse.y;
		gui.setCursor(mouse.centerx, mouse.centery, "none");
	} else {
		gui.setCursor(mouse.savex, mouse.savey, "pointer");
		antigrav.up_factor = 0;
		if (antigrav.momentum_watch > 0) {
			antigrav.momentum_watch -= 1;
		}
	}
}, 1);
setlistener("/devices/status/mice/mouse/button[2]", func(n) {
	mouse.rmb = n.getValue();
	if (antigrav.momentum_watch) {
		antigrav.up_factor = 0;
		antigrav.momentum_watch -= 1;
	}
}, 1);


mouse.loop = func {
	if (mouse.mode or !mouse.mmb) {
		return settimer(mouse.loop, 0);
	}
#	var dx = mouse.x - mouse.centerx;
	var dy = -mouse.y + mouse.centery;
	if (dy) {
		antigrav.input_type = 3;
		antigrav.up_factor = dy * 0.001;
		if (antigrav.momentum_watch < 1) {
			antigrav.momentum_watch = 3;
			coast_up(coast_loop_id += 1);
		}
		gui.setCursor(mouse.centerx, mouse.centery);
	}
	settimer(mouse.loop, 0);
}
mouse.loop();

# keyboard hover ----------------------------------------------------
setlistener("sim/model/daedalus/hover/key-up", func(n) {
	var key_dir = n.getValue();
	if (key_dir) {	# repetitive input or lack of older mod-up may keep triggering
		antigrav.input_type = 1;
		antigrav.up_factor = (key_dir < 0 ? -0.01 : 0.01);
		if (antigrav.momentum_watch <= 0) {
			antigrav.momentum_watch = 3;	# start or reset timer for countdown
			coast_up(coast_loop_id += 1);	# starting from rest, start new loop
		} else {
			antigrav.momentum_watch = 3;	# reset watcher
		}
	} else {
		antigrav.momentum_watch -= 1;
		antigrav.up_factor = 0;
		if (antigrav.momentum_watch < 0) {
			antigrav.momentum_watch = 0;
		}
	}
});

var coast_loop_id = 0;
var coast_up = func (id) {
	id == coast_loop_id or return;
	if (antigrav.momentum_watch >= 3) {
		antigrav.momentum += antigrav.up_factor;
		if (antigrav.input_type == 3) {
			antigrav.up_factor = 0;
		}
		if (abs(antigrav.momentum) > 2.0) {
			antigrav.momentum = (antigrav.momentum < 0 ? -2.0 : 2.0);
		}
	} elsif (antigrav.momentum_watch >= 2) {
		antigrav.momentum_watch -= 1;
	} else {
		antigrav.momentum = antigrav.momentum * 0.75;
		if (abs(antigrav.momentum) < 0.02) {
			antigrav.momentum = 0;
			antigrav.momentum_watch = 0;
		}
	}
	if (antigrav.momentum) {
		up((antigrav.momentum < 0 ? -1 : 1), antigrav.momentum, antigrav.input_type);
	}
	if (antigrav.momentum_watch) {
		settimer(func { coast_up(coast_loop_id += 1) }, 0);
	} else {
		antigrav.momentum = 0;
	}
}

var up = func(hg_dir, hg_thrust, hg_mode) {  # d=direction p=thrust_power m=source of request
	var entry_altitude = altitude_ft_Node.getValue();
	var altitude = entry_altitude;
	contact_altitude = altitude - 5.1 - hover_add;
	if (hg_mode == 1 or hg_mode == 3) {
		# 1 = keyboard , 3 = mouse
		var hg_rise = antigrav.momentum * 4;
	} else {
		# 0 = gravity , 2 = joystick
		var hg_rise = hg_thrust * 4 * hg_dir;
	}
	var contact_rise = contact_altitude + hg_rise;
	if (hg_dir < 0) {    # down requested by drift, fall, or VTOL down buttons
		if (contact_rise < h_contact_target_alt) {  # too low
			contact_rise = h_contact_target_alt + 0.0001;
			if ((contact_rise < contact_altitude) and !antigrav.request) {
				if (asas < 40) {  # ground contact by landing or falling fast
					if (lose_altitude > 0.2 or hg_rise < -0.5) {
						var already_landed = getprop("sim/model/daedalus/position/landing-wow");
						if (!already_landed) {
							setprop("sim/model/daedalus/position/landing-wow", 1);
						}
						lose_altitude = 0;
						if (!engine_request) {
							settle_to_level();
						}
					} else {
						lose_altitude = lose_altitude * 0.5;
					}
				} elsif (lose_altitude > 0.26 and hg_rise < -1.1) {  # ground contact by skidding slowly
					setprop("sim/model/daedalus/position/squeal-wow", 1);
						lose_altitude = lose_altitude * 0.5;
					if (!engine_request) {
						settle_to_level();
					}
				}
			} else {
				lose_altitude = lose_altitude * 0.5;
			}
		}
		if (!antigrav.request) {  # fall unless antigrav just requested
			altitude = contact_rise + 5.1 + hover_add;
			altitude_ft_Node.setDoubleValue(altitude);
			contact_altitude = contact_rise;
		}
	} elsif (hg_dir > 0) {  # up
		if (engines_lvl < 0.5 and engine_level) {  # on standby, power up requested for hover up
			if (power_switch) {
				setprop("sim/model/daedalus/systems/engine-request", 1);
				antigrav.request += 1;   # keep from forgetting until reactor powers up over 0.5
				antigrav.momentum = 0;
			}
		}
		if (engines_lvl > 0.2 and engine_level) {  # sufficient power to comply and lift
			contact_rise = contact_altitude + (engines_lvl * hg_rise);
			altitude = contact_rise + 5.1 + hover_add;
			altitude_ft_Node.setDoubleValue(altitude);
			contact_altitude = contact_rise;
		}
	}
	if ((entry_altitude + hg_rise + 0.01) < altitude) {  # did not achieve full request. must've touched ground
		if (lose_altitude > 0.2) {
			lose_altitude = 0.2;
		}
	}
}

# keyboard and 3-d functions ----------------------------------------

var toggle_power = func(tp_mode) {
	if (tp_mode == 9) {  # clicked from dialog box
		if (!power_switch) {
			setprop("sim/model/daedalus/systems/engine-request", 0);
			setprop("sim/model/daedalus/systems/engine2-request", 0);
			change_maximum(cpl, 0, 2);
		}
	} else {   # clicked from keyboard
		if (power_switch) {
			setprop("sim/model/daedalus/systems/power-switch", 0);
			setprop("sim/model/daedalus/systems/engine-request", 0);
			setprop("sim/model/daedalus/systems/engine2-request", 0);
			change_maximum(cpl, 0, 2);
		} else {
			setprop("sim/model/daedalus/systems/power-switch", 1);
		}
	}
	daedalus.reloadDialog1();
}

var toggle_engine = func {
	if (engine_request) {
		setprop("sim/model/daedalus/systems/engine-request", 0);
	} else {
		if (power_switch) {
			setprop("sim/model/daedalus/systems/engine-request", 1);
		} else {
			popupTip2("Unable to comply. Main power is off.");
		}
	}
	daedalus.reloadDialog1();
}

var toggle_engine2 = func {
	if (engine2_request) {
		setprop("sim/model/daedalus/systems/engine2-request", 0);
	} else {
		if (power_switch) {
			setprop("sim/model/daedalus/systems/engine2-request", 1);
		} else {
			popupTip2("Unable to comply. Main power is off.");
		}
	}
	daedalus.reloadDialog1();
}

setlistener("sim/model/daedalus/crew/cockpit-position", func(n) { cockpitView = n.getValue() });

var set_cockpit = func(cockpitPosition, mode) {
	# axis are different for /sim/current-view
	#  z = aft/fore
	#  x = right/left
	#  y = up/down
	#  mode = (0 = pressed key, save location) or (1 = walked through doorway, do not save location)
	#      or (2 = overlap on stairs, do not save, and do not jump)
	var num_positions = size(cockpit_locations) - 1;
	var last_cpos = getprop("sim/model/daedalus/crew/cockpit-position");
	var actual_cpos = cockpitPosition;
	if (actual_cpos > num_positions) {
		cockpitPosition -= size(cockpit_locations);
	}
	if (mode == 0 and cockpit_locations[last_cpos].can_walk == 1) {
		cockpit_locations[last_cpos].last_x = getprop("sim/model/daedalus/crew/walker/x-offset-m");
		cockpit_locations[last_cpos].last_y = getprop("sim/model/daedalus/crew/walker/y-offset-m");
		cockpit_locations[last_cpos].last_z = getprop("sim/model/daedalus/crew/walker/z-offset-m");
		cockpit_locations[last_cpos].last_h = getprop("sim/current-view/heading-offset-deg");
	}
	if (cockpitPosition > num_positions) {
		cockpitPosition = 0;
	} elsif (cockpitPosition < 0) {
		cockpitPosition = num_positions;
	}
	setprop("sim/model/daedalus/crew/cockpit-position", cockpitPosition);
	if (mode == 1 and hallway_locations[actual_cpos].can_walk == 1) {
		var moveto_x = hallway_locations[actual_cpos].x;
		var moveto_y = hallway_locations[actual_cpos].y;
		var moveto_z = hallway_locations[actual_cpos].z;
		var moveto_h = hallway_locations[actual_cpos].h;
	} elsif (mode != 2) {
		var moveto_x = cockpit_locations[cockpitPosition].last_x;
		var moveto_y = cockpit_locations[cockpitPosition].last_y;
		var moveto_z = cockpit_locations[cockpitPosition].last_z;
		var moveto_h = cockpit_locations[cockpitPosition].last_h;
	}
	if (mode != 2) {
		if (cockpit_locations[cockpitPosition].can_walk == 1) {
			if (!getprop("sim/walker/outside")) {
				setprop("sim/model/daedalus/crew/walker/x-offset-m", moveto_x);
				setprop("sim/model/daedalus/crew/walker/y-offset-m", moveto_y);
				setprop("sim/model/daedalus/crew/walker/z-offset-m", moveto_z);
			}
		}
		if (getprop("sim/current-view/view-number") == 0) {
			setprop("sim/current-view/z-offset-m", moveto_x);
			setprop("sim/current-view/x-offset-m", moveto_y);
			setprop("sim/current-view/y-offset-m", (moveto_z + cockpit_locations[cockpitPosition].z_eye_offset));
			setprop("sim/current-view/goal-heading-offset-deg", moveto_h);
			setprop("sim/current-view/heading-offset-deg", moveto_h);
			setprop("sim/current-view/goal-pitch-offset-deg", cockpit_locations[cockpitPosition].p);
			setprop("sim/current-view/pitch-offset-deg", cockpit_locations[cockpitPosition].p);
			setprop("sim/current-view/field-of-view", cockpit_locations[cockpitPosition].fov);
		}
	}
}

var cycle_cockpit = func(cc_i) {
	if (cc_i == 10) {
		cockpitView = 0;
	} else {
		cockpitView += cc_i;
	}
	set_cockpit(cockpitView, 0);
	if (cc_i == 10) {
		hViewNode.setValue(0.0);
		setprop("sim/current-view/goal-pitch-offset-deg", 0.0);
		setprop("sim/current-view/goal-roll-offset-deg", 0.0);
	}
}

var walk_about_cabin = func(wa_distance, walk_offset) {
	# x,y,z axis are as expected here. Check boundaries/walls.
	#  x = aft/fore
	#  y = right/left
	#  z = up/down
	var w_out = 0;
	var cpos = getprop("sim/model/daedalus/crew/cockpit-position");
	if (cpos == 2 or (cpos >= 4 and cpos <= 7)) {
		var view_head = hViewNode.getValue();
		setprop("sim/model/daedalus/crew/walker/head-offset-deg", view_head);
		var heading = walk_offset + view_head;
		while (heading >= 360.0) {
			heading -= 360.0;
		}
		while (heading < 0.0) {
			heading += 360.0;
		}
		var wa_heading_rad = heading * 0.01745329252;
		var new_x_position = getprop("sim/model/daedalus/crew/walker/x-offset-m") - (math.cos(wa_heading_rad) * wa_distance);
		var new_y_position = getprop("sim/model/daedalus/crew/walker/y-offset-m") - (math.sin(wa_heading_rad) * wa_distance);
		var new_zf_position = cockpit_locations[cpos].z;
		if (cpos == 2) { # bridge
			if (new_y_position > 2.827) {
				# check around exit doorway
				if (new_x_position < -131.8) {
					var y_angle = (new_x_position + 132.70) / 0.90 * 0.88; # (new - -lowest-x-front ) / x-dist * y-dist
					if (new_y_position > (2.6 + y_angle)) {
						new_y_position = 2.6 + y_angle;
					}
				} elsif (new_x_position < -129.87) {
					if (new_y_position > 3.48) {
						new_y_position = 3.48;
					}
				} elsif (new_x_position >= -129.87 and new_x_position < -129.53) {
					var y_angle_r = (new_x_position + 129.87) / 1.61 * 1.34;
					if (new_y_position > (3.48 + y_angle_r)) {
						new_y_position = 3.48 + y_angle_r;
					}
				} elsif (new_x_position > -129.53 and new_x_position < -129.39) {
					var y_angle_r = (new_x_position + 129.87) / 1.61 * 1.34;
					if (new_y_position > (3.48 + y_angle_r)) {
						new_y_position = 3.48 + y_angle_r;
					}
					var y_angle_l = (new_x_position + 129.45) / 0.14 * 0.483;
					if (new_y_position < (2.827 + y_angle_l)) {
						new_y_position = 2.827 + y_angle_l;
					}
				} elsif (new_x_position >= -129.39 and new_x_position < -128.26) {
					var y_angle_r = (new_x_position + 129.87) / 1.61 * 1.34;
					if (new_y_position > (3.48 + y_angle_r)) {
						new_y_position = 3.48 + y_angle_r;
					}
					var y_angle_l = (new_x_position + 129.39) / 1.13 * 1.14;
					if (new_y_position < (3.31 + y_angle_l)) {
						new_y_position = 3.31 + y_angle_l;
					}
				} else {
					# long hallway
					var y_angle_r = (new_x_position + 128.26) / 7.13 * 1.46;
					var y_angle_l = (new_x_position + 128.26) / 3.17 * 0.68;
					if (new_x_position >= -128.26 and new_x_position < -125.09) {
						if (new_y_position > (4.82 + y_angle_r)) {
							new_y_position = 4.82 + y_angle_r;
						} elsif (new_y_position < (4.45 + y_angle_l)) {
							new_y_position = 4.45 + y_angle_l;
						}
					} elsif (new_x_position >= -125.09 and new_x_position < -124.19) {
						if (new_y_position > (4.15 + y_angle_l)) {
							hallway2_clear = 1;	# reset portal jumpoints
						}
						if (new_y_position > (4.82 + y_angle_r)) {
							new_y_position = 4.82 + y_angle_r;
						} elsif (new_y_position < (4.45 + y_angle_l)) {
							var x_angle_r = (5.13 - new_y_position) / 2.12 * 0.47;
							if (new_x_position < (x_angle_r - 125.09)) {
								new_x_position = x_angle_r - 125.09;
							}
							if (new_y_position < 3.01 and hallway2_clear) {
								w_out = 105;
							}
						}
					} elsif (new_x_position >= -124.19 and new_x_position < -119.4) {
						if ((new_y_position > (4.15 + y_angle_l)) and new_x_position < -123.8) {
							hallway2_clear = 1;
						}
						if (new_x_position > -122.34 and hallway2_clear) {
							w_out = 107;
						} else {
							if (new_y_position > (4.82 + y_angle_r)) {
								new_y_position = 4.82 + y_angle_r;
							} elsif (new_y_position > 5.13) {
								if (new_y_position < (4.45 + y_angle_l)) {
									new_y_position = 4.45 + y_angle_l;
								}
							} else {
								if (new_y_position > 4.68) {
									if (new_x_position > -124.19) {
										new_x_position = -124.19;
									}
								} else {
									var x_angle_l = (4.68 - new_y_position) / 2.12 * 0.47;
									if (new_x_position > (x_angle_l - 124.19)) {
										new_x_position = x_angle_l - 124.19;
									}
								}
								if (new_y_position < 3.01 and hallway2_clear) {
									w_out = 105;
								} elsif (new_y_position < -0.18) {
									w_out = 105;
								}
							}
						}
					} else {
						# exit starboard bay
						w_out = 107;
					}
				}
			} else {
				if (new_x_position < -133.28) { # front of bridge
					if (new_y_position > -0.46 and new_y_position < 0.46) {
						if (new_x_position < -134.16) {
							new_x_position = -134.16;
						}
					} elsif (new_y_position > -0.82 and new_y_position < 0.82) {
						var x_angle = (abs(new_y_position) - 0.46) / 0.36 * 0.58;
						if (new_x_position < (-134.74 + x_angle)) {
							new_x_position = -134.74 + x_angle;
						}
					} elsif (new_y_position > -1.51 and new_y_position < 1.51) {
						if (new_x_position < -134.74) {
							new_x_position = -134.74;
						}
					} elsif (new_y_position < -1.81 or new_y_position > 1.81) {
						new_x_position = -133.28;
						if (new_y_position < -2.6) {
							new_y_position = -2.6;
						} elsif (new_y_position > 2.6) {
							new_y_position = 2.6;
						}
					} else {
						if (new_x_position < -133.53) {
							if (new_y_position < -1.51) {
								new_y_position = -1.51;
							} elsif (new_y_position > 1.51) {
								new_y_position = 1.51;
							}
							if (new_x_position < -134.74) {
								new_x_position = -134.74;
							}
						} else {
							var x_angle = (abs(new_y_position) - 1.36) / 0.45 * 0.68;
							if (new_x_position < (-133.96 + x_angle)) {
								new_x_position = -133.96 + x_angle;
							}
						}
					}
				} elsif (new_x_position >= -133.28 and new_x_position < -132.70) {
					if (new_y_position < -2.6) {
						new_y_position = -2.6;
					} elsif (new_y_position > 2.6) {
						new_y_position = 2.6;
					}
				} elsif (new_x_position >= -132.70 and new_x_position <= -131.8) {
					var y_angle = (new_x_position + 132.70) / 0.90 * 0.88;
					if (new_y_position < (-2.6 - y_angle)) {
						new_y_position = -2.6 - y_angle;
					} elsif (new_y_position > (2.6 + y_angle)) {
						new_y_position = 2.6 + y_angle;
					}
				} elsif (new_x_position > -131.8 and new_x_position < -125.4) {
					if (new_y_position < 2.1) {
						if (new_x_position < -130.23) {
							if (new_y_position < -3.48) {
								new_y_position = -3.48;
							}
						} elsif (new_x_position >= -130.23 and new_x_position < -128.65) {
							var y_angle = (new_x_position + 130.23);
							if (new_y_position < (-3.48 + y_angle)) {
								new_y_position = -3.48 + y_angle;
							}
						} elsif (new_x_position >= -128.65 and new_x_position < -125.91) {
							if (new_y_position < -1.9) {
								new_y_position = -1.9;
							} elsif (new_y_position > 1.9) {
								new_y_position = 1.9;
							}
						} elsif (new_x_position >= -125.91 and new_x_position <= -125.6) {
							var y_angle = (new_x_position + 125.91) / 0.31 * 0.20;
							if (new_y_position < (-1.9 + y_angle)) {
								new_y_position = -1.9 + y_angle;
							} elsif (new_y_position > (1.9 - y_angle)) {
								new_y_position = 1.9 - y_angle;
							}
						} elsif (new_x_position > -125.6) {
							new_x_position = -125.6;
							if (new_y_position < -1.7) {
								new_y_position = -1.7;
							} elsif (new_y_position > 1.7) {
								new_y_position = 1.7;
							}
						}
					} else {
						if (new_y_position < 2.827) {
							if (new_x_position > -129.53) {
								var y_angle = (new_x_position + 129.53) / 0.88 * 0.927;
								if (new_y_position > (2.827 - y_angle)) {
									new_y_position = 2.827 - y_angle;
								}
							}
						}
					}
				} elsif (new_x_position > -124.9) {
					if (new_y_position < -0.18) {
						w_out = 105;
					}
					var x_angle_r = (5.13 - new_y_position) / 2.12 * 0.47;
					var x_angle_l = (4.68 - new_y_position) / 2.12 * 0.47;
					if (new_x_position < (x_angle_r - 125.09)) {
						new_x_position = x_angle_r - 125.09;
					}
					if (new_x_position > (x_angle_l - 124.19)) {
						new_x_position = x_angle_l - 124.19;
					}
				}
			}
			# check step up
			if (new_x_position < -129.7 and new_x_position >= -131.04) {
				if (new_y_position < 1.67 and new_y_position > -1.67) {
					new_zf_position += 0.223;
				}
			} elsif (new_x_position >= -129.7 and new_x_position < -125.4 and new_y_position < 2.4) {
				new_zf_position += 0.117;
			}
			# inside objects
			if (new_x_position > -131.54 and new_x_position < -129.27) {
				if (new_y_position > -2.05 and new_y_position < 2.05) {
					if (new_y_position > -2.05 and new_y_position < -1.2) {
						new_y_position = -2.05;
					} elsif (new_y_position >= -1.2 and new_y_position < -0.50) {
						new_y_position = -0.50;
					} elsif (new_y_position > 0.50 and new_y_position < 1.2) {
						new_y_position = 0.50;
					} elsif (new_y_position >= 1.2 and new_y_position < 2.05) {
						new_y_position = 2.05;
					}
				}
				if (new_x_position > -130.64 and new_x_position < -129.4) {
					if (new_y_position > -0.42 and new_y_position < 0.42) {
						if (new_x_position > -129.6 and new_x_position < -129.4) {
							new_x_position = -129.4;
						} elsif (new_x_position > -130.64 and new_x_position < -130.44) {
							new_x_position = -130.64;
						} else {
							if (new_y_position < 0) {
								new_y_position = -0.42;
							} else {
								new_y_position = 0.42;
							}
						}
					}
				}
			} elsif (new_x_position > -127.90 and new_x_position < -126.51) {
				if (new_y_position > -1.37 and new_y_position < 1.37) { # center table
					var x_angle = abs(new_y_position) / 1.37 * 0.29;
					if (new_x_position < -127.41) {
						if (new_x_position > (-127.90 + x_angle)) {
							new_x_position = -127.90 + x_angle;
						}
					} elsif (new_x_position > -127.00) {
						if (new_x_position < (-126.51 - x_angle)) {
							new_x_position = -126.51 - x_angle;
						}
					} else {
						if ((new_x_position > -127.61) and (new_x_position < -126.80)) {
							if (new_y_position < 0) {
								new_y_position = -1.37;
							} else {
								new_y_position = 1.37;
							}
						}
					}
				}
			}
		} elsif (cpos == 4) { # port landing bay
			if (new_x_position <= -97.49) {
				w_out = 4;
			}
			var z_at = getprop("sim/model/daedalus/crew/walker/z-offset-m");
			if (door_position[0] < 0.9) { # door closed creates barrier
				if (new_x_position <= -57.8 and new_x_position >= -59.8) {
					new_x_position = -57.8;
				} elsif (new_x_position <= -59.8 and new_x_position >= -60.37) {
					new_x_position = -60.37;
				}
			} else { # big step up 
				if (new_x_position <= -57.8 and new_x_position >= -60.37) {
					new_zf_position += 0.874;
				}
			}
			if (new_x_position <= -60.37) { # sides in front
				if (new_y_position < -142.7) {
					new_y_position = -142.7;
				} elsif (new_y_position > -85.19) {
					new_y_position = -85.19;
				}
			} elsif (new_x_position < 41.9) { # walls inside
				if (new_y_position < -132.72) {
					new_y_position = -132.72;
				} elsif (new_y_position > -81.25) {
					new_y_position = -81.25;
				}
				if (new_y_position < -96.37 and new_y_position > -117.65) { # ramp
					if (new_x_position < -22 and new_x_position > -57.8) {
						var z_angle = abs(new_x_position + 22) / 35.8 * 0.874;
						new_zf_position += z_angle;
					} elsif (new_x_position > -12.87 and new_x_position < 0.0) { # bay door L-03
						if(door_position[4] > 0) {
							new_zf_position = 6.11 - (clamp(door_position[4], 0, 0.1) * 5);
						}
						if (door_position[4] > 0.81) {
							w_out = (new_x_position > -5.185 ? 4 : 5);
						}
					} elsif (new_x_position > 8.13 and new_x_position < 21.0) { # bay door L-02
						if(door_position[3] > 0) {
							new_zf_position = 6.11 - (clamp(door_position[3], 0, 0.1) * 5);
						}
						if (door_position[3] > 0.81) {
							w_out = (new_x_position > 14.565 ? 4 : 5);
						}
					} elsif (new_x_position > 29.13 and new_x_position < 42.0) { # bay door L-01
						if (door_position[2] > 0) {
							new_zf_position = 6.11 - (clamp(door_position[2], 0, 0.1) * 5);
						}
						if (door_position[2] > 0.81) {
							w_out = (new_x_position > 34.565 ? 4 : 5);
						}
					}
				}
			} else {
				if (new_x_position > 42.1) {
					if (new_y_position < -133.723) {
						new_y_position = -133.723;
					} elsif (new_y_position > -80.217) {
						new_y_position = -80.217;
					}
				} else {
					var y_angle = (new_x_position - 41.9) / 0.2 * 1.033;
					if (new_y_position > (-81.25 + y_angle)) {
						new_y_position = -81.25 + y_angle;
					} elsif (new_y_position < (-132.72 - y_angle)) {
						new_y_position = -132.72 - y_angle;
					}
				}
			}
			if (new_x_position > 45.807 and new_x_position < 46.607) { # railing exists on all levels
				var rail_edge = -87.912;
				if (z_at < 6.2) {
					rail_edge = -85.38;
				}
				if (new_y_position > rail_edge and new_y_position < -81.467) {
					if (new_x_position > 46.207) {
						new_x_position = 46.607;
					} else {
						new_x_position = 45.807;
					}
				}
			}
			if (z_at < 9.911) { # floor and first section of stairs
				if (new_x_position > 46.207 and new_y_position > -89.712) { # under stairs
					if (z_at < 6.2 and new_y_position < -85.08) {
						if (new_y_position > -85.38) {
							new_y_position = -85.38;
						}
					} elsif (new_y_position < -81.867 and new_y_position > -87.512) {
						new_zf_position += abs((81.867 + new_y_position)) / 5.645 * 3.811;
					} elsif (new_y_position <= -87.512) {
						new_zf_position += 3.811;
					}
				}
			} else { # 1st to 2nd landings and 2nd section of stairs
				new_zf_position += 3.811;
				if (new_y_position < -81.867 and new_y_position > -87.512) {
					if (new_x_position > 46.207) {
						new_zf_position -= 3.811;
						new_zf_position += abs((81.867 + new_y_position)) / 5.645 * 3.811;
					} else {
						new_zf_position += (87.512 + new_y_position) / 5.645 * 3.811;
					}
				} elsif (new_y_position >= -81.867) { # 2nd landing
					new_zf_position += 3.811;
					if (new_x_position > 46.607 and new_y_position < -81.467 and 
					    new_y_position > -81.867) { # transition to upper level
						w_out = 205;
					}
				}
				if (new_y_position < -89.212) {
					new_y_position = -89.212;
				}
				if (new_x_position < 44.750) {
					new_x_position = 44.75;
				}
			}
			if (new_x_position >= 47.77) {
				new_x_position = 47.77;
			}
		} elsif (cpos == 5) { # port landing bay catwalk top
			if (new_x_position < -57.6) {
				new_x_position = -57.6;
			} elsif (new_x_position > 47.77) {
				new_x_position = 47.77;
			}
			if (new_y_position < -121.14) {
				new_y_position = -121.14;
			} elsif (new_y_position > -92.80) {
				if (new_x_position < 44.65) {
					new_y_position = -92.80;
				} else { # ramp down
					if (new_y_position >= -90.253) {
						new_zf_position -= 1.517;
					} else {
						new_zf_position -= (new_y_position + 92.3) / 2.047 * 1.517;
					}
					if (new_x_position > 46.207) {
						if (new_y_position > -80.302) {
							new_y_position = -80.302;
						}
						if (new_y_position >= -81.867) {
							new_zf_position -= 4.311;
							if (new_x_position < 46.607) { # transition to lower level
								w_out = 204;
							}
						} elsif (new_y_position > -88.603) {
							if (new_y_position > -88.253) {
								new_zf_position -= (new_y_position + 88.253) / 6.386 * 4.311;
							}
							if (new_x_position < 46.607) {
								new_x_position = 46.607;
							}
						}
					} else {
						if (new_y_position > -78.97) {
							hallway2_clear = 0;
							w_out = 102;
						} elsif (new_y_position > -84.707) {
							if (new_x_position > 45.603) {
								new_x_position = 45.603;
							} elsif (new_x_position < 44.954) {
								new_x_position = 44.954;
							}
						} elsif (new_y_position > -88.603) {
							if (new_x_position > 45.807) {
								new_x_position = 45.807;
							}
						}
					}
					if (new_x_position < 44.75) {
						new_x_position = 44.75;
					}
				}
			}
			if (new_x_position < -4.7) { # split search in half
				if (new_x_position > -56.8 and new_x_position <= -48.7) {
					if ((new_y_position > -113.74 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.6) {
							new_y_position = -100.2;
						} else {
							new_x_position = -56.8;
						}
					}
				} elsif (new_x_position > -48.7 and new_x_position < -44.5) {	# -48.5 -- -44.8
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < -46.65) {
							new_x_position = -48.7;
							if (new_y_position > -113.74 and new_y_position < -113.34) {
								new_y_position = -113.74;
							} elsif (new_y_position > -100.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = -44.5;
						}
					}
				} elsif (new_x_position > -43.8 and new_x_position <= -35.7) {
					if ((new_y_position > -113.74 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.6) {
							new_y_position = -100.2;
						} else {
							new_x_position = -43.8;
						}
					}
				} elsif (new_x_position > -35.7 and new_x_position < -31.5) {
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < -33.65) {
							new_x_position = -35.7;
							if (new_y_position > -113.74 and new_y_position < -113.34) {
								new_y_position = -113.74;
							} elsif (new_y_position > -100.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = -31.5;
						}
					}
				} elsif (new_x_position > -30.8 and new_x_position <= -22.7) {
					if ((new_y_position > -113.74 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.6) {
							new_y_position = -100.2;
						} else {
							new_x_position = -30.8;
						}
					}
				} elsif (new_x_position > -22.7 and new_x_position < -18.5) {
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < -20.65) {
							new_x_position = -22.7;
							if (new_y_position > -113.74 and new_y_position < -112.4) {
								new_y_position = -113.74;
							} elsif (new_y_position > -112.4 and new_y_position < -111.14) {
								new_y_position = -111.14;
							} elsif (new_y_position > -102.80 and new_y_position < -101.5) {
								new_y_position = -102.8;
							} elsif (new_y_position > -101.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = -18.5;
						}
					}
				} elsif (new_x_position > -17.7 and new_x_position <= -9.7) {
					if ((new_y_position > -113.74 and new_y_position < -111.14) or
					    (new_y_position > -102.80 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.5) {
							new_y_position = -100.2;
						} elsif (new_y_position < -111.14 and new_y_position > -111.44) {
							new_y_position = -111.14;
						} elsif (new_y_position > -102.8 and new_y_position < -102.5) {
							new_y_position = -102.8;
						} elsif (new_x_position < -17.4) {
							new_x_position = -17.7;
						}
					}
				} elsif (new_x_position > -9.7 and new_x_position < -5.5) {
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < -7.65) {
							new_x_position = -9.7;
							if (new_y_position > -113.74 and new_y_position < -112.4) {
								new_y_position = -113.74;
							} elsif (new_y_position > -112.4 and new_y_position < -111.14) {
								new_y_position = -111.14;
							} elsif (new_y_position > -102.80 and new_y_position < -101.5) {
								new_y_position = -102.8;
							} elsif (new_y_position > -101.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = -5.5;
						}
					}
				}
			} else {
				if (new_x_position >= -4.7 and new_x_position <= 3.3) {
					if ((new_y_position > -113.74 and new_y_position < -111.14) or
					    (new_y_position > -102.80 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.5) {
							new_y_position = -100.2;
						} elsif (new_y_position < -111.14 and new_y_position > -111.44) {
							new_y_position = -111.14;
						} elsif (new_y_position > -102.8 and new_y_position < -102.5) {
							new_y_position = -102.8;
						} elsif (new_x_position < -4.4) {
							new_x_position = -4.7;
						}
					}
				} elsif (new_x_position > 3.3 and new_x_position < 7.5) {
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < 5.35) {
							new_x_position = 3.3;
							if (new_y_position > -113.74 and new_y_position < -112.4) {
								new_y_position = -113.74;
							} elsif (new_y_position > -112.4 and new_y_position < -111.14) {
								new_y_position = -111.14;
							} elsif (new_y_position > -102.80 and new_y_position < -101.5) {
								new_y_position = -102.8;
							} elsif (new_y_position > -101.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = 7.5;
						}
					}
				} elsif (new_x_position > 8.3 and new_x_position <= 16.3) {
					if ((new_y_position > -113.74 and new_y_position < -111.14) or
					    (new_y_position > -102.80 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.5) {
							new_y_position = -100.2;
						} elsif (new_y_position < -111.14 and new_y_position > -111.44) {
							new_y_position = -111.14;
						} elsif (new_y_position > -102.8 and new_y_position < -102.5) {
							new_y_position = -102.8;
						} elsif (new_x_position < 8.6) {
							new_x_position = 8.3;
						}
					}
				} elsif (new_x_position > 16.3 and new_x_position < 20.5) {
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < 18.35) {
							new_x_position = 16.3;
							if (new_y_position > -113.74 and new_y_position < -112.4) {
								new_y_position = -113.74;
							} elsif (new_y_position > -112.4 and new_y_position < -111.14) {
								new_y_position = -111.14;
							} elsif (new_y_position > -102.80 and new_y_position < -101.5) {
								new_y_position = -102.8;
							} elsif (new_y_position > -101.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = 20.5;
						}
					}
				} elsif (new_x_position >= 21.3 and new_x_position < 29.3) {
					if ((new_y_position > -113.74 and new_y_position < -111.14) or
					    (new_y_position > -102.80 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.5) {
							new_y_position = -100.2;
						} elsif (new_y_position < -111.14 and new_y_position > -111.44) {
							new_y_position = -111.14;
						} elsif (new_y_position > -102.8 and new_y_position < -102.5) {
							new_y_position = -102.8;
						} elsif (new_x_position < 21.6) {
							new_x_position = 21.3;
						}
					}
				} elsif (new_x_position > 29.3 and new_x_position < 33.5) {
					if (new_y_position > -119.74 and new_y_position < -94.2) {
						if (new_y_position < -119.44) {
							new_y_position = -119.74;
						} elsif (new_y_position > -94.5) {
							new_y_position = -94.2;
						} elsif (new_x_position < 31.35) {
							new_x_position = 29.3;
							if (new_y_position > -113.74 and new_y_position < -112.4) {
								new_y_position = -113.74;
							} elsif (new_y_position > -112.4 and new_y_position < -111.14) {
								new_y_position = -111.14;
							} elsif (new_y_position > -102.80 and new_y_position < -101.5) {
								new_y_position = -102.8;
							} elsif (new_y_position > -101.5 and new_y_position < -100.2) {
								new_y_position = -100.2;
							}
						} else {
							new_x_position = 33.5;
						}
					}
				} elsif (new_x_position >= 34.3 and new_x_position < 42.6) {
					if (new_y_position < -94.2 and new_x_position > 42.3) {
						new_x_position = 42.3;
					}
					if ((new_y_position > -113.74 and new_y_position < -111.14) or
					    (new_y_position > -102.80 and new_y_position < -100.2)) {
						if (new_y_position < -113.34) {
							new_y_position = -113.74;
						} elsif (new_y_position > -100.5) {
							new_y_position = -100.2;
						} elsif (new_y_position < -111.14 and new_y_position > -111.44) {
							new_y_position = -111.14;
						} elsif (new_y_position > -102.8 and new_y_position < -102.5) {
							new_y_position = -102.8;
						} elsif (new_x_position < 34.6) {
							new_x_position = 34.3;
						}
					}
				} elsif (new_x_position >= 42.6 and new_y_position < -94.25) {
					new_y_position = -94.25;
				}
			}
			if (new_y_position >= -111.44 and new_y_position <= -102.50) {
				new_zf_position += 1.35;
			} elsif (new_y_position > -113.44 and new_y_position < -111.44) {
				new_zf_position += (new_y_position + 113.44) / 2 * 1.35;
			} elsif (new_y_position > -102.50 and new_y_position < -100.5) {
				new_zf_position += abs((new_y_position + 100.5)) / 2 * 1.35;
			}
		} elsif (cpos == 6) { # starboard landing bay
			if (new_x_position <= -97.49) {
				w_out = 6;
			}
			var z_at = getprop("sim/model/daedalus/crew/walker/z-offset-m");
			if (door_position[1] < 0.9) {
				if (new_x_position <= -57.8 and new_x_position >= -59.8) {
					new_x_position = -57.8;
				} elsif (new_x_position <= -59.8 and new_x_position >= -60.37) {
					new_x_position = -60.37;
				}
			} else {
				if (new_x_position <= -57.8 and new_x_position >= -60.37) {
					new_zf_position += 0.874;
				}
			}
			if (new_x_position <= -60.37) {
				if (new_y_position > 142.7) {
					new_y_position = 142.7;
				} elsif (new_y_position < 85.19) {
					new_y_position = 85.19;
				}
			} elsif (new_x_position < 41.9) {
				if (new_y_position > 132.72) {
					new_y_position = 132.72;
				} elsif (new_y_position < 81.25) {
					new_y_position = 81.25;
				}
				if (new_y_position > 96.949 and new_y_position < 118.23) {
					if (new_x_position < -22 and new_x_position > -57.8) {
						var z_angle = abs(new_x_position + 22) / 35.8 * 0.874;
						new_zf_position += z_angle;
					} elsif (new_x_position > -12.87 and new_x_position < 0.0) { # bay door R-04
						if(door_position[5] > 0) {
							new_zf_position = 6.11 - (clamp(door_position[5], 0, 0.1) * 5);
						}
						if (door_position[5] > 0.81) {
							w_out = (new_x_position > -5.185 ? 6 : 7);
						}
					} elsif (new_x_position > 8.13 and new_x_position < 21.0) { # bay door R-05
						if(door_position[6] > 0) {
							new_zf_position = 6.11 - (clamp(door_position[6], 0, 0.1) * 5);
						}
						if (door_position[6] > 0.81) {
							w_out = (new_x_position > 14.565 ? 6 : 7);
						}
					} elsif (new_x_position > 29.13 and new_x_position < 42.0) { # bay door R-06
						if(door_position[7] > 0) {
							new_zf_position = 6.11 - (clamp(door_position[7], 0, 0.1) * 5);
						}
						if (door_position[7] > 0.81) {
							w_out = (new_x_position > 34.565 ? 6 : 7);
						}
					}
				}
			} else {
				if (new_x_position > 42.1) {
					if (new_y_position > 133.723) {
						new_y_position = 133.723;
					} elsif (new_y_position < 80.217) {
						new_y_position = 80.217;
					}
				} else {
					var y_angle = (new_x_position - 41.9) / 0.2 * 1.033;
					if (new_y_position < (81.25 - y_angle)) {
						new_y_position = 81.25 - y_angle;
					} elsif (new_y_position > (132.72 + y_angle)) {
						new_y_position = 132.72 + y_angle;
					}
				}
			}
			if (new_x_position > 45.807 and new_x_position < 46.607) {
				var rail_edge = 87.912;
				if (z_at < 6.2) {
					rail_edge = 85.38;
				}
				if (new_y_position < rail_edge and new_y_position > 81.467) {
					if (new_x_position > 46.207) {
						new_x_position = 46.607;
					} else {
						new_x_position = 45.807;
					}
				}
			}
			if (z_at < 9.911) {
				if (new_x_position > 46.207 and new_y_position < 89.712) {
					if (z_at < 6.2 and new_y_position > 85.08) {
						if (new_y_position < 85.38) {
							new_y_position = 85.38;
						}
					} elsif (new_y_position > 81.867 and new_y_position < 87.512) {
						new_zf_position += (new_y_position - 81.867) / 5.645 * 3.811;
					} elsif (new_y_position >= 87.512) {
						new_zf_position += 3.811;
					}
				}
			} else {
				new_zf_position += 3.811;
				if (new_y_position > 81.867 and new_y_position < 87.512) {
					if (new_x_position > 46.207) {
						new_zf_position -= 3.811;
						new_zf_position += (new_y_position - 81.867) / 5.645 * 3.811;
					} else {
						new_zf_position += (87.512 - new_y_position) / 5.645 * 3.811;
					}
				} elsif (new_y_position <= 81.867) {
					new_zf_position += 3.811;
					if (new_x_position > 46.607 and new_y_position > 81.467 and 
					    new_y_position < 81.867) {
						w_out = 207;
					}
				}
				if (new_y_position > 89.212) {
					new_y_position = 89.212;
				}
				if (new_x_position < 44.750) {
					new_x_position = 44.75;
				}
			}
			if (new_x_position >= 47.77) {
				new_x_position = 47.77;
			}
		} elsif (cpos == 7) { # starboard staircase
			if (new_x_position < -57.6) {
				new_x_position = -57.6;
			} elsif (new_x_position > 47.77) {
				new_x_position = 47.77;
			}
			if (new_y_position > 121.14) {
				new_y_position = 121.14;
				new_zf_position += 1.517;
			} elsif (new_y_position < 92.80) {
				if (new_x_position < 44.65) {
					new_y_position = 92.80;
					new_zf_position += 1.517;
				} else {
					if (new_y_position >= 92.5) {
						new_zf_position += 1.517;
					} elsif (new_y_position > 90.253) {
						new_zf_position += (new_y_position - 90.253) / 2.047 * 1.517;
					}
					if (new_x_position > 46.207) {
						if (new_y_position < 80.302) {
							new_y_position = 80.302;
						}
						if (new_y_position <= 81.867) {
							new_zf_position -= 4.311;
							if (new_x_position < 46.607) {
								w_out = 206;
							}
						} elsif (new_y_position < 88.603) {
							if (new_y_position < 88.253) {
								new_zf_position += (new_y_position - 88.253) / 6.386 * 4.311;
							}
							if (new_x_position < 46.607) {
								new_x_position = 46.607;
							}
						}
					} else {
						if (new_y_position < 78.97) {
							hallway2_clear = 0;
							w_out = 111;
						} elsif (new_y_position < 84.707) {
							if (new_x_position > 45.603) {
								new_x_position = 45.603;
							} elsif (new_x_position < 44.954) {
								new_x_position = 44.954;
							}
						} elsif (new_y_position < 88.603) {
							if (new_x_position > 45.807) {
								new_x_position = 45.807;
							}
						}
					}
					if (new_x_position <= 44.75) {
						new_x_position = 44.75;
					}
				}
			} else {
				new_zf_position += 1.517;
			}
			if (new_x_position < -4.7) { # split search in half
				if (new_x_position > -56.8 and new_x_position <= -48.7) {
					if ((new_y_position < 113.74 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.6) {
							new_y_position = 100.2;
						} else {
							new_x_position = -56.8;
						}
					}
				} elsif (new_x_position > -48.7 and new_x_position < -44.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < -46.65) {
							new_x_position = -48.7;
							if (new_y_position < 113.74 and new_y_position > 113.34) {
								new_y_position = 113.74;
							} elsif (new_y_position < 100.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = -44.5;
						}
					}
				} elsif (new_x_position > -43.8 and new_x_position <= -35.7) {
					if ((new_y_position < 113.74 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.6) {
							new_y_position = 100.2;
						} else {
							new_x_position = -43.8;
						}
					}
				} elsif (new_x_position > -35.7 and new_x_position < -31.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < -33.65) {
							new_x_position = -35.7;
							if (new_y_position < 113.74 and new_y_position > 113.34) {
								new_y_position = 113.74;
							} elsif (new_y_position < 100.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = -31.5;
						}
					}
				} elsif (new_x_position > -30.8 and new_x_position <= -22.7) {
					if ((new_y_position < 113.74 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.6) {
							new_y_position = 100.2;
						} else {
							new_x_position = -30.8;
						}
					}
				} elsif (new_x_position > -22.7 and new_x_position < -18.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < -20.65) {
							new_x_position = -22.7;
							if (new_y_position < 113.74 and new_y_position > 112.4) {
								new_y_position = 113.74;
							} elsif (new_y_position < 112.4 and new_y_position > 111.14) {
								new_y_position = 111.14;
							} elsif (new_y_position < 102.80 and new_y_position > 101.5) {
								new_y_position = 102.8;
							} elsif (new_y_position < 101.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = -18.5;
						}
					}
				} elsif (new_x_position > -17.7 and new_x_position <= -9.7) {
					if ((new_y_position < 113.74 and new_y_position > 111.14) or
					    (new_y_position < 102.80 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.5) {
							new_y_position = 100.2;
						} elsif (new_y_position > 111.14 and new_y_position < 111.44) {
							new_y_position = 111.14;
						} elsif (new_y_position < 102.8 and new_y_position > 102.5) {
							new_y_position = 102.8;
						} elsif (new_x_position < -17.4) {
							new_x_position = -17.7;
						}
					}
				} elsif (new_x_position > -9.7 and new_x_position < -5.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < -7.65) {
							new_x_position = -9.7;
							if (new_y_position < 113.74 and new_y_position > 112.4) {
								new_y_position = 113.74;
							} elsif (new_y_position < 112.4 and new_y_position > 111.14) {
								new_y_position = 111.14;
							} elsif (new_y_position < 102.80 and new_y_position > 101.5) {
								new_y_position = 102.8;
							} elsif (new_y_position < 101.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = -5.5;
						}
					}
				}
			} else {
				if (new_x_position >= -4.7 and new_x_position <= 3.3) {
					if ((new_y_position < 113.74 and new_y_position > 111.14) or
					    (new_y_position < 102.80 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.5) {
							new_y_position = 100.2;
						} elsif (new_y_position > 111.14 and new_y_position < 111.44) {
							new_y_position = 111.14;
						} elsif (new_y_position < 102.8 and new_y_position > 102.5) {
							new_y_position = 102.8;
						} elsif (new_x_position < -4.4) {
							new_x_position = -4.7;
						}
					}
				} elsif (new_x_position > 3.3 and new_x_position < 7.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < 5.35) {
							new_x_position = 3.3;
							if (new_y_position < 113.74 and new_y_position > 112.4) {
								new_y_position = 113.74;
							} elsif (new_y_position < 112.4 and new_y_position > 111.14) {
								new_y_position = 111.14;
							} elsif (new_y_position < 102.80 and new_y_position > 101.5) {
								new_y_position = 102.8;
							} elsif (new_y_position < 101.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = 7.5;
						}
					}
				} elsif (new_x_position > 8.3 and new_x_position <= 16.3) {
					if ((new_y_position < 113.74 and new_y_position > 111.14) or
					    (new_y_position < 102.80 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.5) {
							new_y_position = 100.2;
						} elsif (new_y_position > 111.14 and new_y_position < 111.44) {
							new_y_position = 111.14;
						} elsif (new_y_position < 102.8 and new_y_position > 102.5) {
							new_y_position = 102.8;
						} elsif (new_x_position < 8.6) {
							new_x_position = 8.3;
						}
					}
				} elsif (new_x_position > 16.3 and new_x_position < 20.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < 18.35) {
							new_x_position = 16.3;
							if (new_y_position < 113.74 and new_y_position > 112.4) {
								new_y_position = 113.74;
							} elsif (new_y_position < 112.4 and new_y_position > 111.14) {
								new_y_position = 111.14;
							} elsif (new_y_position < 102.80 and new_y_position > 101.5) {
								new_y_position = 102.8;
							} elsif (new_y_position < 101.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = 20.5;
						}
					}
				} elsif (new_x_position >= 21.3 and new_x_position < 29.3) {
					if ((new_y_position < 113.74 and new_y_position > 111.14) or
					    (new_y_position < 102.80 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.5) {
							new_y_position = 100.2;
						} elsif (new_y_position > 111.14 and new_y_position < 111.44) {
							new_y_position = 111.14;
						} elsif (new_y_position < 102.8 and new_y_position > 102.5) {
							new_y_position = 102.8;
						} elsif (new_x_position < 21.6) {
							new_x_position = 21.3;
						}
					}
				} elsif (new_x_position > 29.3 and new_x_position < 33.5) {
					if (new_y_position < 119.74 and new_y_position > 94.2) {
						if (new_y_position > 119.44) {
							new_y_position = 119.74;
						} elsif (new_y_position < 94.5) {
							new_y_position = 94.2;
						} elsif (new_x_position < 31.35) {
							new_x_position = 29.3;
							if (new_y_position < 113.74 and new_y_position > 112.4) {
								new_y_position = 113.74;
							} elsif (new_y_position < 112.4 and new_y_position > 111.14) {
								new_y_position = 111.14;
							} elsif (new_y_position < 102.80 and new_y_position > 101.5) {
								new_y_position = 102.8;
							} elsif (new_y_position < 101.5 and new_y_position > 100.2) {
								new_y_position = 100.2;
							}
						} else {
							new_x_position = 33.5;
						}
					}
				} elsif (new_x_position >= 34.3 and new_x_position < 42.6) {
					if (new_y_position > 94.2 and new_x_position > 42.3) {
						new_x_position = 42.3;
					}
					if ((new_y_position < 113.74 and new_y_position > 111.14) or
					    (new_y_position < 102.80 and new_y_position > 100.2)) {
						if (new_y_position > 113.34) {
							new_y_position = 113.74;
						} elsif (new_y_position < 100.5) {
							new_y_position = 100.2;
						} elsif (new_y_position > 111.14 and new_y_position < 111.44) {
							new_y_position = 111.14;
						} elsif (new_y_position < 102.8 and new_y_position > 102.5) {
							new_y_position = 102.8;
						} elsif (new_x_position < 34.6) {
							new_x_position = 34.3;
						}
					}
				} elsif (new_x_position >= 42.6 and new_y_position > 94.25) {
					new_y_position = 94.25;
				}
			}
			if (new_y_position <= 111.44 and new_y_position >= 102.50) {
				new_zf_position += 1.35;
			} elsif (new_y_position < 113.44 and new_y_position > 111.44) {
				new_zf_position += (113.44 - new_y_position) / 2 * 1.35;
			} elsif (new_y_position < 102.50 and new_y_position > 100.5) {
				new_zf_position += (new_y_position - 100.5) / 2 * 1.35;
			}
		}
		if (w_out) {
			var sc_mode = int(w_out * 0.01);
			if (sc_mode) {
				var sc_goto = w_out - (sc_mode * 100);
				set_cockpit(sc_goto, sc_mode);
			} else {
				walk.get_out(w_out);
			}
		} else {
			if (getprop("sim/current-view/view-number") == 0) {
				xViewNode.setValue(new_x_position);
				yViewNode.setValue(new_y_position);
				zViewNode.setValue(new_zf_position + 1.659);
			}
			setprop("sim/model/daedalus/crew/walker/x-offset-m", new_x_position);
			setprop("sim/model/daedalus/crew/walker/y-offset-m", new_y_position);
			setprop("sim/model/daedalus/crew/walker/z-offset-m", new_zf_position);
		}
	}
}

# dialog functions --------------------------------------------------

var set_nav_lights = func(snl_i) {
	nav_light_switch.setValue(snl_i);
	active_nav_button = [ 3, 3, 3];
	if (snl_i == 0) {
		active_nav_button[0]=1;
	} elsif (snl_i == 1) {
		active_nav_button[1]=1;
	} else {
		active_nav_button[2]=1;
	}
	nav_lighting_update();
}

var set_landing_lights = func(sll_i) {
	var sll_new = landing_light_switch.getValue();
	if (sll_i == -1) {
		sll_new += 1;
		if (sll_new > 2) {
			sll_new = 0;
		}
	} else {
		sll_new = sll_i;
	}
	landing_light_switch.setValue(sll_new);
	active_landing_button = [ 3, 3, 3];
	if (sll_new == 0) {
		active_landing_button[0]=1;
	} elsif (sll_new == 1) {
		active_landing_button[1]=1;
	} else {
		active_landing_button[2]=1;
	}
	nav_lighting_update();
	daedalus.reloadDialog1();
}

var set_guide_lights = func(sgl_i) {
	guide_light_mode_Node.setValue(sgl_i);
	daedalus.reloadDialog1();
}

var reloadDialog1 = func {
	name = "daedalus-config";
	interior_lighting_update();
	if (config_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		config_dialog = nil;
		showDialog1();
		return;
	}
}

var showDialog = func {
	var c_view = getprop("sim/current-view/view-number");
	var outside = getprop("sim/walker/outside");
	if (outside and ((c_view == view.indexof("Walk View")) or (c_view == view.indexof("Walker Orbit View")))) {
		walker.sequence.showDialog();
	} else {
		showDialog1();
	}
}

var showDialog1 = func {
	name = "daedalus-config";
	if (config_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		config_dialog = nil;
		return;
	}

	config_dialog = gui.Widget.new();
	config_dialog.set("layout", "vbox");
	config_dialog.set("name", name);
	config_dialog.set("x", -40);
	config_dialog.set("y", -40);

 # "window" titlebar
	titlebar = config_dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Daedalus X-305 configuration");
	titlebar.addChild("empty").set("stretch", 1);

	config_dialog.addChild("hrule").addChild("dummy");

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("daedalus.config_dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	var checkbox = func {
		group = config_dialog.addChild("group");
		group.set("layout", "hbox");
		group.addChild("empty").set("pref-width", 4);
		box = group.addChild("checkbox");
		group.addChild("text").set("label", arg[0]);
		group.addChild("empty").set("stretch", 1);

		box.set("halign", "left");
		box.set("label", "");
		box.set("live", 1);
		return box;
	}
	var d1p = getprop("sim/model/daedalus/systems/power-switch");
 # master power switch
	w = checkbox("master power                          [~]");
	w.setColor(0.45, (0.45 + (d1p * 0.55)), 0.45);
	w.set("property", "sim/model/daedalus/systems/power-switch");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.toggle_power(9)");

 # atmospheric engine
	w = checkbox("atmospheric engines                 [\]");
	w.setColor(0.45, (0.45 + (d1p * getprop("sim/model/daedalus/systems/engine-request") * 0.55)), 0.45);
	w.set("property", "sim/model/daedalus/systems/engine-request");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	w = checkbox("second large engines               [space]");
	w.setColor(0.45, (0.45 + (d1p * getprop("sim/model/daedalus/systems/engine2-request") * 0.55)), 0.45);
	w.set("property", "sim/model/daedalus/systems/engine2-request");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

 # orbital velocities and hyperdrive glow
	w = checkbox("increase energy flow to hyperdrive");
	w.setColor(0.45, (0.45 + (d1p * getprop("sim/model/daedalus/systems/ftl3-request") * 0.55)), 0.45);
	w.set("property", "sim/model/daedalus/systems/ftl3-request");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	config_dialog.addChild("hrule").addChild("dummy");

 # interior
	w = checkbox("interior lights");
	w.setColor(0.45, (0.45 + (d1p * getprop("sim/model/daedalus/lighting/interior-switch") * 0.55)), 0.45);
	w.set("property", "sim/model/daedalus/lighting/interior-switch");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

 # exterior lights
	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "nav lights:");
	g.addChild("empty").set("stretch", 1);

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);

	box = g.addChild("button");
	g.addChild("empty").set("stretch", 1);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("legend", "Stay On");
	box.set("border", active_nav_button[2]);
	box.setColor(0.45, (0.975 - (active_nav_button[2] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_nav_lights(2)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 18);
	box.set("legend", "Dusk to Dawn");
	box.set("border", active_nav_button[1]);
	box.setColor(0.45, (0.975 - (active_nav_button[1] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_nav_lights(1)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 50);
	box.set("pref-height", 18);
	box.set("legend", "Off");
	box.set("border", active_nav_button[0]);
	box.setColor((0.975 - (active_nav_button[0] * 0.175)), 0.45, 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_nav_lights(0)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	# beacons
	w = checkbox("beacons");
	w.setColor(0.45, (0.45 + (d1p * getprop("controls/lighting/beacon") * 0.55)), 0.45);
	w.set("property", "controls/lighting/beacon");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "landing lights:");
	g.addChild("empty").set("stretch", 1);

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);

	box = g.addChild("button");
	g.addChild("empty").set("stretch", 1);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("legend", "Stay On");
	box.set("border", active_landing_button[2]);
	box.setColor(0.45, (0.975 - (active_landing_button[2] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_landing_lights(2)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 18);
	box.set("legend", "Dusk to Dawn");
	box.set("border", active_landing_button[1]);
	box.setColor(0.45, (0.975 - (active_landing_button[1] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_landing_lights(1)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 50);
	box.set("pref-height", 18);
	box.set("legend", "Off");
	box.set("border", active_landing_button[0]);
	box.setColor((0.975 - (active_landing_button[0] * 0.175)), 0.45, 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_landing_lights(0)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

 #  landing bay guide lights
	w = checkbox("landing bay guide lights");
	w.setColor(0.45, (0.45 + (d1p * getprop("controls/lighting/baydoor-guide") * 0.55)), 0.45);
	w.set("property", "controls/lighting/baydoor-guide");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("daedalus.reloadDialog1()");

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);

	box = g.addChild("button");
	g.addChild("empty").set("stretch", 1);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("legend", "Strobe Out");
	box.set("border", active_guide_button[0]);
	box.setColor(0.45, (0.975 - (active_guide_button[0] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_guide_lights(-1)");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 80);
	box.set("pref-height", 18);
	box.set("legend", "No Strobe");
	box.set("border", active_guide_button[1]);
	if (getprop("controls/lighting/baydoor-guide")) {
		box.setColor(0.45, (0.975 - (active_guide_button[1] * 0.175)), 0.45);
	} else {
		box.setColor((0.975 - (active_guide_button[1] * 0.175)), 0.45, 0.45);
	}
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_guide_lights(0)");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("legend", "Strobe In");
	box.set("border", active_guide_button[2]);
	box.setColor(0.45, (0.975 - (active_guide_button[2] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("daedalus.set_guide_lights(1)");

	config_dialog.addChild("hrule").addChild("dummy");

	 # units of measure
	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Instrumentation units of measure:");
	g.addChild("empty").set("stretch", 1);

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Altitude:");
	g.addChild("empty").set("stretch", 1);
	var combo = g.addChild("combo");
	combo.set("default-padding", 1);
	combo.set("default-value", "None");
	combo.set("pref-width", 150);
	combo.set("live", 0);
	combo.set("property", "/sim/gui/dialogs/altitude");
	for (var i = 0 ; i < size(digitalPanel.altitude_modes) ; i += 1) {
		combo.set("value[" ~ (i) ~ "]", digitalPanel.altitude_modes[i]);
	}
	digitalPanel.gui_altitude_node.setValue(digitalPanel.altitude_modes[digitalPanel.altitude_mode.getValue()]);
	combo.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	combo.prop().getNode("binding[1]/command", 1).setValue("nasal");
	combo.prop().getNode("binding[1]/script", 1).setValue("digitalPanel.combobox_a_apply()");
	g.addChild("empty").set("pref-width", 4);

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Heading:");
	g.addChild("empty").set("stretch", 1);
	var combo = g.addChild("combo");
	combo.set("default-padding", 1);
	combo.set("default-value", "None");
	combo.set("pref-width", 150);
	combo.set("live", 0);
	combo.set("property", "/sim/gui/dialogs/heading");
	for (var i = 0 ; i < size(digitalPanel.heading_modes) ; i += 1) {
		combo.set("value[" ~ (i) ~ "]", digitalPanel.heading_modes[i]);
	}
	digitalPanel.gui_heading_node.setValue(digitalPanel.heading_modes[digitalPanel.head_mode.getValue()]);
	combo.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	combo.prop().getNode("binding[1]/command", 1).setValue("nasal");
	combo.prop().getNode("binding[1]/script", 1).setValue("digitalPanel.combobox_h_apply()");
	g.addChild("empty").set("pref-width", 4);

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Velocity:");
	g.addChild("empty").set("stretch", 1);
	var combo = g.addChild("combo");
	combo.set("default-padding", 1);
	combo.set("default-value", "None");
	combo.set("pref-width", 150);
	combo.set("live", 0);
	combo.set("property", "/sim/gui/dialogs/velocity");
	for (var i = 0 ; i < size(digitalPanel.velocity_modes) ; i += 1) {
		combo.set("value[" ~ (i) ~ "]", digitalPanel.velocity_modes[i]);
	}
	digitalPanel.gui_velocity_node.setValue(digitalPanel.velocity_modes[digitalPanel.vel_mode.getValue()]);
	combo.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	combo.prop().getNode("binding[1]/command", 1).setValue("nasal");
	combo.prop().getNode("binding[1]/script", 1).setValue("digitalPanel.combobox_v_apply()");
	g.addChild("empty").set("pref-width", 4);

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "GPS:");
	g.addChild("empty").set("stretch", 1);
	var combo = g.addChild("combo");
	combo.set("default-padding", 1);
	combo.set("default-value", "None");
	combo.set("pref-width", 150);
	combo.set("live", 0);
	combo.set("property", "/sim/gui/dialogs/gps");
	for (var i = 0 ; i < size(digitalPanel.gps_modes) ; i += 1) {
		combo.set("value[" ~ (i) ~ "]", digitalPanel.gps_modes[i]);
	}
	digitalPanel.gui_gps_node.setValue(digitalPanel.gps_modes[digitalPanel.gps_mode.getValue()]);
	combo.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	combo.prop().getNode("binding[1]/command", 1).setValue("nasal");
	combo.prop().getNode("binding[1]/script", 1).setValue("digitalPanel.combobox_g_apply()");
	g.addChild("empty").set("pref-width", 4);

	config_dialog.addChild("hrule").addChild("dummy");

	# simple and fast shadow - alternative to Rendered AC shadow
	w = checkbox("Simple 2D shadow");
	w.set("property", "sim/model/daedalus/shadow");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	# logo
	config_dialog.addChild("hrule").addChild("dummy");
	config_dialog.addChild("text").set("label", "Logo texture:");
	var content = config_dialog.addChild("input");
	content.set("name", "input");
	content.set("layout", "hbox");
	content.set("halign", "fill");
	content.set("label", "");
	content.set("default-padding", 1);
	content.set("pref-width", 200);
	content.set("editable", 1);
	content.set("live", 1);
	content.set("property", "sim/model/daedalus/logo/texture");
	content.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	content.prop().getNode("binding[0]/object-name", 1).setValue("input");

 # finale
	config_dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", config_dialog.prop());
	gui.showDialog(name);
}

var gui_livery_node = props.globals.getNode("/sim/gui/dialogs/livery", 1);
var livery_hull_list = [ "hull-1", "hull-2", "hull-3", "texture-4", "texture-5", "texture-6", "texture-7", "texture-8", "texture-9", "hull-cockpit", "stripe"];
if (gui_livery_node.getNode("list") == nil) {
	gui_livery_node.getNode("list", 1).setValue("");
}
for (var i = 0; i < size(livery_hull_list); i += 1) {
	gui_livery_node.getNode("list["~i~"]", 1).setValue(livery_hull_list[i]);
}
gui_livery_node = gui_livery_node.getNode("list", 1);

var listbox_apply = func {
	material.showDialog("sim/model/livery/material/" ~ gui_livery_node.getValue() ~ "/", nil, getprop("/sim/startup/xsize") - 200, 20);
}

var showLiveryDialog1 = func {
	name = "daedalus-livery-select";
	if (livery_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		livery_dialog = nil;
		return;
	}

	livery_dialog = gui.Widget.new();
	livery_dialog.set("layout", "vbox");
	livery_dialog.set("name", name);
	livery_dialog.set("x", 40);
	livery_dialog.set("y", -40);

 # "window" titlebar
	titlebar = livery_dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Daedalus ");
	titlebar.addChild("empty").set("stretch", 1);

	livery_dialog.addChild("hrule").addChild("dummy");

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("daedalus.livery_dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	g = livery_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Edit External Livery Hull materials:");
	g.addChild("empty").set("stretch", 1);

	var a = livery_dialog.addChild("list");
	a.set("name", "livery-hull-list");
	a.set("pref-width", 300);
	a.set("pref-height", 160);
	a.set("slider", 18);
	a.set("property", "/sim/gui/dialogs/livery/list");
	for (var i = 0 ; i < size(livery_hull_list) ; i += 1) {
		a.set("value[" ~ i ~ "]", livery_hull_list[i]);
	}
	a.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	a.prop().getNode("binding[0]/object-name", 1).setValue("livery-hull-list");
	a.prop().getNode("binding[1]/command", 1).setValue("nasal");
	a.prop().getNode("binding[1]/script", 1).setValue("daedalus.listbox_apply()");
	g.addChild("empty").set("pref-width", 4);

	livery_dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", livery_dialog.prop());
	gui.showDialog(name);
}

#==========================================================================
#                 === initial calls at startup ===
setlistener("sim/signals/fdm-initialized", func {
	update_main();  # starts continuous loop
	settimer(interior_lighting_loop, 0.25);
	settimer(interior_lighting_update, 0.5);
	settimer(nav_light_loop, 0.5);
	settimer(reset_landing, 1.0);
	aircraft.livery.select(getprop("sim/model/livery/name"));
	setprop("sim/atc/enabled", 0);
	setprop("sim/sound/chatter", 0);

	print ("X-305 Daedalus  by Stewart Andreason, Grzegorz Wereszko");
	print ("  version 5.01  release date 2014.May.10  for FlightGear 1.9+");
});
