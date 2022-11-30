/*
LMS-schema.psql
By: Petrus Matiros & Tomas Weldetinsae
Modified: 2021-10-07
*/

-- To-Do:
-- Admin_account "maintains" Books or book_copies???


/*
* Book schema
* To store info about unique books
*
* Constraints:
* a book can only have max 5 physical copies
* a book shouldn't have 0 physical copies
*/
-- to add: date of publication
CREATE TABLE Book (
  bookID int,
  title varchar NOT NULL,
  num_of_copies integer,
  PRIMARY KEY (bookID),
  CHECK (num_of_copies >= 0 AND num_of_copies <= 5)
);

-- CREATE TYPE file_format AS ENUM (
--   'AAC', 'MP3', 'WAV', 'FLAC'
-- );

-- CREATE TYPE audio_bitrate AS ENUM (
--   '32 kbps', '64 kbps', '96 kbps', '128 kbps'
-- );

-- /*
-- * Audio_Book schema
-- * To store info about audiobook versions of the books in the database
-- */
-- -- should this be apart of the case study?
-- CREATE TABLE Audio_Book (
--   audioBookID int,
--   bookID int,
--   title varchar NOT NULL,
--   length interval NOT NULL,
--   file_type file_format NOT NULL,
--   file_size_MB int NOT NULL,
--   audio_quality audio_bitrate NOT NULL,
--   narrator_firstname varchar NOT NULL,
--   narrator_lastname varchar NOT NULL,
--   PRIMARY KEY (audioBookID),
--   FOREIGN KEY (bookID) REFERENCES Book(bookID)
-- );

/*
* Book_copy schema
* To store info about book copies (physical copies) of the books in the database
*/
-- to add: damaged information; missing_pages, water_damage, burnt, torn, damage_description
-- add it in seperate schema?
CREATE TABLE Book_copy (
  copyID int,
  bookID int,
  publisher varchar NOT NULL,
  date_of_publication date NOT NULL,
  language varchar NOT NULL,
  edition varchar,
  status varchar NOT NULL,
  health_status varchar NOT NULL,
  ISBN varchar(17),
  PRIMARY KEY (copyID),
  FOREIGN KEY (bookID) REFERENCES Book(bookID)
);

/*
* Book_author schema
* To store info about the authors of the books in the database
*/
CREATE TABLE Book_author (
  bookID int,
  author_firstname varchar NOT NULL,
  author_lastname varchar NOT NULL,
  PRIMARY KEY (bookID)
);

/*
* Book_genre schema
* To store info about the genres of the books in the database
*/
CREATE TABLE Book_genre (
  bookID int,
  genre varchar,
  PRIMARY KEY (bookID, genre)
);


/*
* PreSeq schema
* To store info about the prequels and sequels of the books in the database
*/
CREATE TABLE PreSeq (
  bookID int,
  prequelID int,
  sequelID int,
  PRIMARY KEY (bookID),
  FOREIGN KEY (prequelID) REFERENCES Book(bookID),
  FOREIGN KEY (sequelID) REFERENCES Book(bookID)
);

/*
* Member schema
* To store info about the members that can use/access the database
*/
CREATE TABLE Member (
  kthID int,
  first_name varchar NOT NULL,
  last_name varchar NOT NULL,
  member_role char(1) NOT NULL,
  PRIMARY KEY (kthID),
  CHECK (member_role = 'S' OR member_role = 'A')
);

/*
* Student_account schema
* To store info about the accounts that are interacted with in the database
*
* Constraints:
* an student account can only have 4 books borrowed at the same time (slots)
* an student account can only borrow a book for 7 days
*/
-- add constraint (students), if fine is not paid --> cannot borrow
CREATE TABLE Student_account (
  student_accountID int,
  kthID int,
  email varchar,
  address varchar,
  programme varchar,
  admin_privileges boolean NOT NULL,
  borrow_slots integer,
  limit_duration_cap integer,
  PRIMARY KEY (student_accountID),
  FOREIGN KEY (kthID) REFERENCES Member(kthID),
  CHECK ((borrow_slots >= 0 AND borrow_slots <= 4) AND (limit_duration_cap >= 0 AND limit_duration_cap <= 7))
);

/*
* Admin_account schema
* To store info about the accounts that are interacted with in the database
*/
CREATE TABLE Admin_account (
  admin_accountID int,
  kthID int,
  email varchar,
  address varchar,
  phone_number varchar,
  department varchar,
  admin_privileges boolean NOT NULL,
  PRIMARY KEY (admin_accountID),
  FOREIGN KEY (kthID) REFERENCES Member(kthID)
);

/*
* Loan_entry schema
* To store info about the loan entries that are done in the database
* GETDATE()
*
* Constraints:
* an student account can only borrow the same book 6 times
*/
CREATE TABLE Loan_entry (
  loanID int,
  copyID int,
  student_accountID int,
  date_of_loan date NOT NULL,
  time_of_loan time NOT NULL,
  expire_date date NOT NULL,
  is_returned boolean NOT NULL,
  times_reborrowed int NOT NULL,
  date_of_return date,
  time_of_return time,
  PRIMARY KEY (loanID),
  FOREIGN KEY (copyID) REFERENCES Book_copy(copyID),
  FOREIGN KEY (student_accountID) REFERENCES Student_account(student_accountID),
  CHECK (times_reborrowed <= 6)
);

/*
* Fine_info schema
* To store info about the fines that are processed in the database
*
* Constraints:
* the fine_amount cannot be less than 0
* the number_of_days_late cannot be less than 0
*/
CREATE TABLE Fine_info (
  fineID int,
  loanID int,
  number_of_days_late integer NOT NULL,
  fine_amount integer NOT NULL,
  PRIMARY KEY (fineID),
  FOREIGN KEY (loanID) REFERENCES Loan_entry(loanID),
  CHECK (fine_amount >= 0 AND number_of_days_late >= 0)
);


CREATE TYPE payment_method AS ENUM (
  'cash', 'card', 'swish', 'klarna'
);

CREATE TABLE Transaction_info (
  transactionID int,
  fineID int,
  date_of_payment date,
  method_of_payment payment_method NOT NULL,
  PRIMARY KEY (transactionID),
  FOREIGN KEY (fineID) REFERENCES Fine_info(fineID)
);


