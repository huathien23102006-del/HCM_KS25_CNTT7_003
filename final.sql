-- tạo database
CREATE DATABASE if not exists BOOKING_DB;
USE BOOKING_DB;

-- tạo bảng guest
CREATE TABLE if not exists GUESTS (
guest_id INT PRIMARY KEY AUTO_INCREMENT,
full_name VARCHAR(50) NOT NULL,
email VARCHAR(255) UNIQUE NOT NULL,
phone VARCHAR(15) UNIQUE NOT NULL,
loyalty_points int default 0
constraint chk_point CHECK(loyalty_points >= 0)
);

-- tạo bảng guest_profiles
CREATE TABLE IF NOT EXISTS GUEST_PROFILES (
profile_id INT PRIMARY KEY auto_increment,
guest_id int not null,
address varchar(255) not null,
birthday date not null,
national_id varchar(50) unique not null,
foreign key (guest_id) references GUESTS (guest_id)
);

-- tạo bảng rooms
create table if not exists Rooms (
room_id int primary key auto_increment,
room_name varchar(100) not null,
room_type varchar(100) not null,
price_per_night decimal(10, 0) not null,
room_status varchar(100),
constraint chk_price check(price_per_night > 0)
);

-- tạo bảng bookings
create table if not exists Bookings (
booking_id int primary key auto_increment,
guest_id int not null,
check_in_date datetime not null,
check_out_date datetime not null,
total_charge decimal(10, 0) not null,
booking_status varchar(50) not null,
room_id int not null,
foreign key (guest_id) references GUESTS(guest_id),
foreign key (room_id) references Rooms(room_id),
constraint chk_out_date check(check_out_date > check_in_date),
constraint chck_total check(total_charge > 0)
);

-- tạo bảng Room_log
create table if not exists Room_Log (
log_id int primary key auto_increment,
room_id int not null,
action_type varchar(100) not null,
change_note text not null,
logged_at datetime default current_timestamp,
foreign key (room_id) references Rooms(room_id)
);

-- chèn dữ liệu bảng khách lưu trú
insert into GUESTS (full_name, email, phone, loyalty_points)
values
('Nguyen Van A','anv@gmail.com','901234567', 150),
('Tran Thi B', 'btt@gmail.com','912345678', 500),
('Le van C','cle@gmail.com','92234455', 0),
('Pham Minh D','dpham@gmail.com','933445566', 1000),
('Hoang Anh E','ehoang@gmail.com','944556677', 20);

-- chèn dữ liệu bảng hồ sơ chi tiết khách 
insert into GUEST_PROFILES (profile_id, guest_id, address, birthday, national_id)
values
(101, 1, '123 Le Loi, Q1, HCM', '1990-5-15', '12345'),
(102, 2, '456 Nguyen Hue, Q1, HCM', '1985-10-20', '23456'),
(103, 3, '789 Phan Chu Trinh, Da Nang', '1995-12-1', '34567'),
(104, 4, '101 Hoang Ha Tham, Ha Noi', '1988-3-25', '45678'),
(105, 5, '202 Tran Hung Dao, Can Tho', '2000-7-10', '56789');

-- chèn dữ liệu bảng phòng
insert into Rooms (room_id, room_name, room_type, price_per_night, room_status)
values
(1,'Room 101', 'Standard', 100000, 'Available'),
(2,'Room 202', 'Deluxe', 5000000, 'Occupied'),
(3,'Room 303', 'Suite', 300000, 'Available'),
(4,'Room 104', 'Standard', 200000, 'Occupied'),
(5,'Room 205', 'Deluxe', 2000000, 'Maintenance');

-- chèn dữ liệu giao dịch đặt phòng
insert into Bookings (booking_id, guest_id, check_in_date, check_out_date, total_charge, booking_status, room_id)
values
(1001, 1, '2023-11-15 10:30', '2023-11-18 12:00', 300000, 'Completed', 1),
(1002, 2, '2023-12-1 14:20', '2023-12-4 12:00', 20000000, 'Completed', 2),
(1003, 1, '2021-1-10 9:15', '2021-1-11 12:00', 5000000, 'Pending', 2),
(1004, 3, '2023-5-20 16:45', '2023-5-22 12:00', 900000,'Cancelled', 3),
(1005, 4, '2024-1-18 11:00', '2024-1-20 12:00', 8000000, 'Completed', 4);

-- chèn dữ liệu nhật ký biến động phòng
insert into Room_Log (room_id, action_type, change_note, logged_at)
values
(1, 'Check-in', 'Guest check in', '2023-10-1 8:00'),
(1,'Check-out', 'Guest check out', '2023-11-15 10:35'),
(4, 'Maintenance', 'Room reported as damaged', '2023-11-20 15:00'),
(2, 'Check-in', 'New guest arrival', '2023-11-25 9:00'),
(3, 'Maintenance', 'Schedule maintenance', '2023-12-1 13:00');

-- update + 200d cho cac khach hang co duoi email @gmail.com
UPDATE GUESTS 
SET loyalty_points = loyalty_points + 200
WHERE email like '%@gmail.com';

-- Xóa các bản ghi có logged_at trước ngày 10/11/2023
DELETE FROM Room_Log 
WHERE logged_at < '2023-11-10';

-- lấy ra danh sách phòng có giá thuê > 1m hoặc status = MAintenance hoặc type = Suite
SELECT room_name, price_per_night, room_status 
FROM Rooms
WHERE (price_per_night > 1000000) 
		OR (room_status = 'MAintenance') 
		OR (room_type = 'Suite');

-- Lấy thông tin khách hàng có email thuộc domain @gmail.com và points trong khoảng 50-300
SELECT full_name, email 
FROM GUESTS
WHERE email like '%@gmail.com' 
			AND loyalty_points 
				BETWEEN 50 AND 300;


DROP TRIGGER IF EXISTS trg_after_update_booking_status
DELIMITER $$
CREATE TRIGGER trg_after_update_booking_status
AFTER UPDATE ON Room_Log
FOR EACH ROW
BEGIN
	if booking_status = 'Completed' THEN
		UPDATE Room_Log
        SET action_type = 'Check-out',
			change_note = 'Booking Completed',
            logged_at = NOW();
	END IF;
END $$
DELIMITER ;


DROP TRIGGER IF EXISTS trg_update_loyalty_points;

DELIMITER $$
CREATE TRIGGER trg_update_loyalty_points
BEFORE UPDATE ON Guests
FOR EACH ROW
BEGIN
	IF booking_status = 'Completed' THEN
		UPDATE GUESTS
		SET loyalty_points = loyalty_points + 2
		WHERE total_charge >= 1000000;
	END IF;
END $$
DELIMITER ;

-- câu 1
DELIMITER $$
CREATE PROCEDURE sp_get_room_status (IN room_id int)
BEGIN
	DECLARE status_chk VARCHAR(50);
    
    SELECT room_status INTO status_chk 
    FROM Rooms
    WHERE room_id = room_id;
    
    IF room_status = 'Available'
    THEN SELECT 'Phòng trống' AS MESSAGE;
    END IF;
    
    IF room_status = 'Occupied'
    THEN SELECT 'Đang có khách' AS MESSAGE;
    END IF;
    
    IF room_status = 'Maintenance' 
    THEN SELECT 'Bảo trì' AS MESSAGE;
    END IF;
END $$
DELIMITER ;
