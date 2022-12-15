/**
* Name: Build01
* Author: B1906448 B1906488 B19064
*/

model Build01

global {
	file shapeFileBuilding <- file("../includes/buildings.shp");
	file shapeFileRoad <- file("../includes/roads.shp");
	geometry shape <- envelope(shapeFileBuilding);
	graph roadNetwork;
	geometry free_space;
	float timeStep <- 0.05;
	float tiLeBiDapChet <- 0.5;
	float tiLeChetSS <- 0.5;
	
	int egg <- 0;
	int larva <- 1;
	int pupa <- 2;
	int mosquito <- 3;
	int dead <- 4;
	list<int> chuKySong <- [1, 6, 2, 60, 1];
	list<float> tiLeChet <- [0.005, 0.0009, 0.0009, 0, 0];
	
	int soMuoi update: Aedes count (each.giaiDoan = mosquito);
	int soTrung update: Aedes count (each.giaiDoan = egg);
	int soBoGay update: Aedes count (each.giaiDoan = larva);
	int soLangQuang update: Aedes count (each.giaiDoan = pupa);
	int soChet update: Aedes count (each.giaiDoan = dead);
	int soNguoiChuaMB update: nguoi count (!each.nhiemBenh and !each.khangBenh);
	int soNguoiNhiem update: nguoi count (each.nhiemBenh);
	int soNguoiKhangBenh update: nguoi count (each.khangBenh);
	
	float khoangCachDot <- 10.0;
	
	init{
		free_space <- copy(shape);
		create building from: shapeFileBuilding;
		create road from: shapeFileRoad;
		roadNetwork <- as_edge_graph(road);
		create quanTheMuoi number: 5{
			location <- any_location_in(free_space);
			free_space <- free_space - (shape + 400.0);
		}
		create Aedes number: 100{
			quanTheMuoi tmpQT <- any(quanTheMuoi);
			qt <- tmpQT;
			location <- any_location_in(tmpQT);
			nhiemBenh <- false;
			giaiDoan <- mosquito;
			color <- #green;
		}
		create nguoi number: 1000{
			location <- any_location_in(any(building));
			nhiemBenh <- false;
			color <- #green;
		}
		quanTheMuoi tmQT <- one_of(quanTheMuoi);
		tmQT.color <- #red;
		create nguoi number: 10{
			location <- any_location_in(tmQT);
			nhiemBenh <- true;
			color <- #red;
		}
		create Aedes number: 50{
			qt <- tmQT;
			location <- any_location_in(tmQT);
			nhiemBenh <- false;
			giaiDoan <- mosquito;
			color <- #green;
		}
	}
}

species building{	
	aspect geom{
		draw shape color: rgb(170, 166, 186);
	}
}

species road{
	aspect geom{
		draw (shape) color: rgb(136, 130, 158);
	}
}

species quanTheMuoi{
	rgb color <- #purple;
	geometry shape <- circle(400#m);
	
	aspect geom{
		draw circle(400) color: color wireframe: true;
	}
}

species Aedes skills: [moving]{
	quanTheMuoi qt;
	rgb color;
	point target;
	float speed <- 10 #km/#h;
	bool nhiemBenh <- false;
	int soLanSS;
	float tgUBenhMax <- rnd(8.0, 10.0);
	float tgUBenh <- 0.0;
	int giaiDoan; //egg, larva, pupa, mosquito or dead
	float tgSong <- 0.0;
	bool dot <- false;
	list<nguoi> nguoiOGan update: nguoi at_distance khoangCachDot;
	
	init{
		soLanSS <- rnd (3, 5);
		tgSong <- 0.0;
		nhiemBenh <- false;
		tgUBenh <- 0.0;
		dot <- false;
	}
	
	reflex leave when: (target = nil){
		target <- any_location_in(qt);
	}
	
	reflex move when: target != nil and giaiDoan = mosquito{
		do goto target: target;
		if (location = target){
			target <- nil;
		}
	}
	
	reflex doiMau{
		if (giaiDoan < 3){
			color <- #black;
		} else if (nhiemBenh){
			color <- #orange;
		} else{
			color <- #green;
		}
	}
	
	reflex truongThanh{
		tgSong <- tgSong + timeStep;
		if (tgSong > chuKySong[giaiDoan]){
			giaiDoan <- giaiDoan + 1;
			tgSong <- 0.0;
		}
		if (giaiDoan < mosquito){
			if (flip((soBoGay + soTrung) > 5000 ? 0.5 : tiLeChet[giaiDoan])){
				do die;
			}
		}
		if (giaiDoan = dead){
			do die;
		}
	}
	
	reflex sinhSan when: giaiDoan = mosquito and soLanSS > 0 and dot{
		if (flip(0.1)){
			create species(self) number: rnd(100, 120){
				self.giaiDoan <- egg;
				self.qt <- myself.qt;
				self.location <- myself.location;
				self.tgSong <- 0.0;
			}
			soLanSS <- soLanSS - 1;
		}
	}
	
	reflex dot when: giaiDoan = mosquito{
		if (!empty(nguoiOGan)){
			if (!dot){
				dot <- true;
			}
			if (nhiemBenh){
				nguoi muctieu <- one_of(nguoiOGan);
				if (!muctieu.nhiemBenh and !muctieu.khangBenh){
					muctieu.tgUBenh <- muctieu.tgUBenh + timeStep;
				}	
			}else{
				nguoi muctieu <- one_of(nguoiOGan);
				if ((muctieu.nhiemBenh or muctieu.tgUBenh > 0.0) and !nhiemBenh){
					tgUBenh <- tgUBenh + timeStep;
				}
			}
			if (flip(soMuoi > 500 ? tiLeBiDapChet : 0.0009)){
				do die;
			}
		}
	}
	
	reflex uBenh when: tgUBenh > 0.0 and tgUBenh <= tgUBenhMax{
		tgUBenh <- tgUBenh + timeStep;
		if (tgUBenh >= tgUBenhMax){
			nhiemBenh <- true;
		}
	}
	
	aspect geom{
		draw triangle(10) color: color;
		if (tgUBenh > 0.0 or nhiemBenh){
			draw circle(10) color: #orange wireframe: true;
		}
	}
}

species nguoi skills: [moving]{
	point target;
	rgb color;
	float proba_leave <- 0.005;
	float speed <- 50 #km/#h;
	bool nhiemBenh <- false;
	bool khangBenh <- false;
	float tgUBenh <- 0.0;
	float tgUBenhMax <- rnd(3.0, 14.0);
	float tgHoiPhucMax <- rnd(5.0, 7.0);
	float tgHoiPhuc <- 0.0;
	
	reflex leave when: (target = nil) and (flip(proba_leave)){
		target <- any_location_in(any(building));
	}
	
	reflex move when: target != nil{
		do goto target: target on: roadNetwork;
		if (location = target){
			target <- nil;
		}
	}
	
	reflex uBenh when: tgUBenh > 0.0 and tgUBenh <= tgUBenhMax{
		tgUBenh <- tgUBenh + timeStep;
		if (tgUBenh >= tgUBenhMax){
			nhiemBenh <- true;
		}
	}
	
	reflex hoiPhuc when: nhiemBenh{
		tgHoiPhuc <- tgHoiPhuc + timeStep;
		if (tgHoiPhuc >= tgHoiPhucMax){
			nhiemBenh <- false;
			khangBenh <- true;
			tgUBenh <- 0.0;
		}
	}
	
	reflex doiMau{
		if (khangBenh){
			color <- #blue;
		} else{
			if (nhiemBenh){
				color <- #red;
			} else{
				color <- #green;
			}
		}
	}
	
	aspect geom{
		draw circle(5) color: color;
		if (tgUBenh > 0.0 or nhiemBenh or khangBenh){
			draw circle(10) color: color wireframe: true;
		}
	}
}

experiment Run type: gui {
	output {
		monitor "So con muoi truong thanh" value: soMuoi;
		monitor "So Trung" value: soTrung;
		monitor "So Bo Gay" value: soBoGay;
		monitor "So Loang Quang" value: soLangQuang;
		monitor "So nguoi khoe manh" value: soNguoiChuaMB;
		monitor "So nguoi nhiem benh" value: soNguoiNhiem;
		monitor "So nguoi da co de khang" value: soNguoiKhangBenh;
		display map{
			species building aspect: geom;
			species road aspect: geom;
			species quanTheMuoi aspect: geom;
			species Aedes aspect: geom;
			species nguoi aspect: geom;
		}
		display chart{
			chart "BIEU DO SU TANG TRUONG SO LUONG CA NHIEM BENH" type: series{
				data "So nguoi khoe manh" value: nguoi count (!each.nhiemBenh) color: #green;
				data "So nguoi nhiem benh" value: nguoi count (each.nhiemBenh) color: #red;
				data "So nguoi da co de khang" value: nguoi count (each.khangBenh) color: #blue;
			}
		}
	}
}
