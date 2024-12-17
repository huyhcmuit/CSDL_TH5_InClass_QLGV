CREATE DATABASE QuanLyGiaoVu
--Tao bang khoa
CREATE TABLE KHOA
(
	MAKHOA varchar(4) primary key, 
	TENKHOA varchar(40),
	NGTLAP smalldatetime,
	TRGKHOA char(4)
);
--Tao bang mon hoc
CREATE TABLE MONHOC
(
	MAMH varchar(10) primary key,
	TENMH varchar(40),
	TCLT tinyint, 
	TCTH tinyint, 
	MAKHOA varchar(4),
	FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
);
--Tao bang dieu kien
CREATE TABLE DIEUKIEN
(
	MAMH varchar(10), 
	MAMH_TRUOC varchar(10),
	primary key (MAMH, MAMH_TRUOC),
	FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH), 
	FOREIGN KEY (MAMH_TRUOC) REFERENCES MONHOC(MAMH)
);
--Tao bang giao vien
CREATE TABLE GIAOVIEN
(
	MAGV char(4) primary key, 
	HOTEN varchar(40), 
	HOCVI varchar(10),
	HOCHAM varchar(10), 
	GIOITINH varchar(3),
	NGSINH smalldatetime, 
	NGVL smalldatetime,
	HESO numeric(4,2),
	MUCLUONG money, 
	MAKHOA varchar(4),
	FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
);
--Tao bang lop
CREATE TABLE LOP
(
	MALOP char(3) primary key,
	TENLOP varchar(40), 
	TRGLOP char(5),
	SISO tinyint,
	MAGVCN char(4),
	FOREIGN KEY (MAGVCN) REFERENCES GIAOVIEN(MAGV)
);
--Tao bang hoc vien
CREATE TABLE HOCVIEN
(
	MAHV char(5) primary key,
	HO varchar(40),
	TEN varchar(10), 
	NGSINH smalldatetime,
	GIOITINH varchar(3), 
	NOISINH varchar(40),
	MALOP char(3), 
	GHICHU varchar(100),
	DIEMTB numeric(4,2),
	XEPLOAI varchar(20),
	FOREIGN KEY (MALOP) REFERENCES LOP(MALOP)
);
--Tao bang giang day
CREATE TABLE GIANGDAY
(
	MALOP char(3), 
	MAMH varchar(10),
	MAGV char(4),
	HOCKY tinyint,
	NAM smallint,
	TUNGAY smalldatetime,
	DENNGAY smalldatetime,
	primary key (MALOP, MAMH),
	FOREIGN KEY (MALOP) REFERENCES LOP(MALOP),
	FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH),
	FOREIGN KEY (MAGV) REFERENCES GIAOVIEN(MAGV)
);
--Tao bang ket qua thi
CREATE TABLE KETQUATHI
(
	MAHV char(5),
	MAMH varchar(10),
	LANTHI tinyint,
	NGTHI smalldatetime,
	DIEM numeric(4,2),
	KQUA varchar(10),
	primary key (MAHV, MAMH, LANTHI),
	FOREIGN KEY (MAHV) REFERENCES HOCVIEN(MAHV),
	FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH)
);
--Them khoa ngoai bo sung
ALTER TABLE KHOA
ADD FOREIGN KEY (TRGKHOA) REFERENCES GIAOVIEN(MAGV);

ALTER TABLE LOP
ADD FOREIGN KEY (TRGLOP) REFERENCES HOCVIEN(MAHV);

--Cau 3
ALTER TABLE HOCVIEN
ADD CONSTRAINT check_GIOITINH CHECK(GIOITINH IN ('Nam','Nu'));

--Cau 4:
ALTER TABLE KETQUATHI
ADD CONSTRAINT check_DIEM CHECK (DIEM >=0 AND DIEM <=10);

--Cau 5:
ALTER TABLE KETQUATHI
ADD CONSTRAINT check_KQ CHECK ((DIEM >=5 AND KQUA = 'Dat') OR (DIEM < 5 AND KQUA = 'Khong dat'));

--Cau 6:
ALTER TABLE KETQUATHI
ADD CONSTRAINT check_LANTHI CHECK (LANTHI <= 3);

--Cau 7:
ALTER TABLE GIANGDAY
ADD CONSTRAINT check_HOCKY CHECK (HOCKY BETWEEN 1 AND 3);

--Cau 8:
ALTER TABLE GIAOVIEN
ADD CONSTRAINT check_HOCVI CHECK (HOCVI IN ('CN', 'KS','Ths', 'TS', 'PTS'));

--TH5 
--Phan I 
--Cau 9
GO
CREATE TRIGGER trg_Check_LopTruong
ON LOP
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN HOCVIEN H ON I.TRGLOP = H.MAHV
        WHERE I.MALOP <> H.MALOP
    )
    BEGIN
        RAISERROR (N'Lop truong phai la hoc vien cua lop ðo.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 10 
GO
CREATE TRIGGER trg_Check_TruongKhoa
ON KHOA
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN GIAOVIEN G ON I.TRGKHOA = G.MAGV
        WHERE G.MAKHOA <> I.MAKHOA 
        OR G.HOCVI NOT IN ('TS', 'PTS')
    )
    BEGIN
        RAISERROR (N'Truong khoa phai la giao vien thuoc khoa va co hoc vi TS hoac PTS.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 15
GO
CREATE TRIGGER trg_Check_ThiSauHoc
ON KETQUATHI
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN HOCVIEN HV ON I.MAHV = HV.MAHV
        JOIN GIANGDAY GD ON GD.MALOP = HV.MALOP AND GD.MAMH = I.MAMH
        WHERE I.NGTHI <= GD.DENNGAY
    )
    BEGIN
        RAISERROR (N'Hoc vien chi duoc thi khi lop da hoc xong mon hoc.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 16
GO
CREATE TRIGGER trg_Check_ToiDa3Mon
ON GIANGDAY
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT MALOP, HOCKY, NAM
        FROM GIANGDAY
        GROUP BY MALOP, HOCKY, NAM
        HAVING COUNT(MAMH) > 3
    )
    BEGIN
        RAISERROR (N'Moi hoc ky, lop chi duoc hoc toi da 3 mon.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 17 
GO
CREATE TRIGGER trg_Update_SiSo
ON HOCVIEN
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE L
    SET SISO = (SELECT COUNT(*) FROM HOCVIEN H WHERE H.MALOP = L.MALOP)
    FROM LOP L;
END;
GO
--Cau 18 
GO
CREATE TRIGGER trg_Check_DIEUKIEN
ON DIEUKIEN
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DIEUKIEN D1
        JOIN DIEUKIEN D2 
        ON D1.MAMH = D2.MAMH_TRUOC AND D1.MAMH_TRUOC = D2.MAMH
        WHERE D1.MAMH <= D1.MAMH_TRUOC
    )
    BEGIN
        RAISERROR (N'Rang buoc mon hoc bi trung hoac nguoc nhau.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 19 
GO
CREATE TRIGGER trg_Check_MucLuong
ON GIAOVIEN
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT HOCVI, HOCHAM, HESO
        FROM GIAOVIEN
        GROUP BY HOCVI, HOCHAM, HESO
        HAVING COUNT(DISTINCT MUCLUONG) > 1
    )
    BEGIN
        RAISERROR (N'Giao vien co cung hoc vi, hoc ham, he so luong thi muc luong phai bang nhau.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 20 
GO
CREATE TRIGGER trg_Check_ThiLai
ON KETQUATHI
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN KETQUATHI K ON I.MAHV = K.MAHV AND I.MAMH = K.MAMH AND I.LANTHI = K.LANTHI + 1
        WHERE K.DIEM >= 5
    )
    BEGIN
        RAISERROR (N'Hoc vien chi duoc thi lai khi diem truoc do duoi 5.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 21 
GO
CREATE TRIGGER trg_Check_NgayThi
ON KETQUATHI
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN KETQUATHI K ON I.MAHV = K.MAHV AND I.MAMH = K.MAMH AND I.LANTHI = K.LANTHI + 1
        WHERE I.NGTHI <= K.NGTHI
    )
    BEGIN
        RAISERROR (N'Ngay thi lan sau phai lon hon ngay thi lan truoc.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 22 
GO
CREATE TRIGGER trg_Check_ThuTuGiangDay
ON GIANGDAY
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN DIEUKIEN D ON I.MAMH = D.MAMH
        WHERE NOT EXISTS (
            SELECT 1
            FROM GIANGDAY G
            WHERE G.MAMH = D.MAMH_TRUOC AND G.MALOP = I.MALOP AND G.DENNGAY <= I.TUNGAY
        )
    )
    BEGIN
        RAISERROR (N'Chua hoc xong mon truoc, khong the hoc mon sau.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Cau 23 
GO
CREATE TRIGGER trg_Check_GiangDayKhoa
ON GIANGDAY
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN GIAOVIEN G ON I.MAGV = G.MAGV
        JOIN MONHOC M ON I.MAMH = M.MAMH
        WHERE G.MAKHOA <> M.MAKHOA
    )
    BEGIN
        RAISERROR (N'Giao vien chi duoc day mon thuoc khoa cua minh.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
--Em khong thay cau 24 a^^
-------------------------------END----------------------------------------

