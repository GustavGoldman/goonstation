///This is exclusively for the AI map right now
/obj/station_map
	name = "AI station map"
	var/static/icon/map_icon

	var/x_max = 1
	var/x_min = null
	var/y_max = 1
	var/y_min = null

	var/border_width = 20

	New()
		..()
		x_min = world.maxx
		y_min = world.maxy
		if (!map_icon)
			map_icon = icon('icons/obj/station_map.dmi', "blank")
			#ifdef UPSCALED_MAP
			map_icon.Scale(world.maxx, world.maxy)
			#endif
			render_map()
			zoom_map()
			pixel_y += 20 //magic numbers because ByondUI mis-aligns by a few pixels
			pixel_x += 8
		icon = map_icon

	Click(location, control, params)
		if (!isAI(usr)) //only for AI use
			return
		var/list/param_list = params2list(params)
		if ("left" in param_list)
			var/x = text2num(param_list["icon-x"])
			var/y = text2num(param_list["icon-y"])
			var/turf/clicked = locate(x, y, Z_LEVEL_STATION)
			if (isAIeye(usr))
				usr.loc = clicked
			else
				var/mob/living/silicon/ai/mainframe = usr
				mainframe.eye_view() //pop out to eye first
				mainframe.eyecam.loc = clicked //then tele it, not our core
		if ("right" in param_list)
			return TRUE

	///Checks whether a turf be rendered on the map.
	proc/valid_turf(var/turf/turf)
		if (!turf.loc)
			return FALSE
		var/area/A = turf.loc
		if (!A.render_on_map)
			return FALSE
		// The Kondaru off station owlry and abandoned research outpost are both considered part of the station but have no AI cams
		if ((map_settings.name in list("KONDARU", "DONUT3")) && (istype(turf.loc, /area/station/garden/owlery) || istype(turf.loc, /area/research_outpost/indigo_rye)))
			return FALSE
		return TRUE

	//generates the map from the current station layout
	proc/render_map()
		for (var/y in world.maxy to 1 step -1)
			for (var/x in 1 to world.maxx)
				var/turf/turf = locate(x, y, Z_LEVEL_STATION)
				if (!src.valid_turf(turf))
					continue
				//keep track of the outer bounds of the station
				x_max = max(x_max, x)
				x_min = min(x_min, x)
				y_max = max(y_max, y)
				y_min = min(y_min, y)
				map_icon.DrawBox(turf_color(turf), x,y)

	//zooms and centers the map on the station
	proc/zoom_map()
		var/scale_x = world.maxx / ((x_max - x_min) + border_width)
		var/scale_y = world.maxy / ((y_max - y_min) + border_width)
		var/scale_main = min(scale_x, scale_y)
		//scale the whole thing to the largest axis
		src.Scale(scale_main, scale_main)

		//work out the center of the station
		var/center_x = (x_max + x_min)/2
		var/center_y = (y_max + y_min)/2
		//adjust by distance to real center
		src.pixel_x = -(center_x - (world.maxx/2)) * scale_main
		src.pixel_y = -(center_y - (world.maxy/2)) * scale_main

	proc/turf_color(turf/turf)
		if (!turf.loc)
			return
		var/area/A = turf.loc
		return A.station_map_colour
