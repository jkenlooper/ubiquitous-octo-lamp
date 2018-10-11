DROP TABLE if exists Chill;
DROP TABLE if exists Node;
DROP TABLE if exists Node_Node;
DROP TABLE if exists Query;
DROP TABLE if exists Route;
DROP TABLE if exists Template;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Chill (
    version integer
);
COMMIT;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Node (
    id integer primary key,
    name varchar(255),
    value text,
    template integer,
    query integer,
    foreign key ( template ) references Template ( id ) on delete set null,
    foreign key ( query ) references Query ( id ) on delete set null
    );
INSERT INTO "Node" VALUES(1,'frontpage',NULL,1,1);
INSERT INTO "Node" VALUES(2,'page',NULL,NULL,1);
INSERT INTO "Node" VALUES(3,'description','Massively Multiplayer Online Jigsaw Puzzles',NULL,NULL);
INSERT INTO "Node" VALUES(4,'content','frontpage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(5,'gallery',NULL,2,1);
INSERT INTO "Node" VALUES(6,'recent',NULL,NULL,2);
INSERT INTO "Node" VALUES(7,'preview',NULL,3,1);
INSERT INTO "Node" VALUES(8,'recent',NULL,NULL,3);
INSERT INTO "Node" VALUES(9,'players',NULL,NULL,4);
INSERT INTO "Node" VALUES(20,'footerpages',NULL,NULL,1);
INSERT INTO "Node" VALUES(21,'footerpages_item',NULL,5,1);
INSERT INTO "Node" VALUES(22,'content','faqpage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(23,'title','FAQ''s',NULL,NULL);
INSERT INTO "Node" VALUES(24,'description','Frequently Asked Questions',NULL,NULL);
INSERT INTO "Node" VALUES(25,'footerpages_item',NULL,5,1);
INSERT INTO "Node" VALUES(26,'content','contactpage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(27,'title','Contact',NULL,NULL);
INSERT INTO "Node" VALUES(28,'description','a contact form',NULL,NULL);
INSERT INTO "Node" VALUES(33,'footerpages_item',NULL,5,1);
INSERT INTO "Node" VALUES(34,'description','About page for online jigsaw puzzle site: Puzzle Massive',NULL,NULL);
INSERT INTO "Node" VALUES(35,'title','About',NULL,NULL);
INSERT INTO "Node" VALUES(36,'content','aboutpage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(37,'slug','contact',NULL,NULL);
INSERT INTO "Node" VALUES(38,'slug','about',NULL,NULL);
INSERT INTO "Node" VALUES(39,'slug','faq',NULL,NULL);
INSERT INTO "Node" VALUES(40,'order','30',NULL,NULL);
INSERT INTO "Node" VALUES(41,'order','10',NULL,NULL);
INSERT INTO "Node" VALUES(42,'order','40',NULL,NULL);
INSERT INTO "Node" VALUES(43,'footerpages_item',NULL,5,1);
INSERT INTO "Node" VALUES(44,'description','Tutorial for new players',NULL,NULL);
INSERT INTO "Node" VALUES(45,'title','Help',NULL,NULL);
INSERT INTO "Node" VALUES(46,'content','helppage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(47,'slug','help',NULL,NULL);
INSERT INTO "Node" VALUES(48,'order','20',NULL,NULL);
INSERT INTO "Node" VALUES(49,'footerpages_item',NULL,5,1);
INSERT INTO "Node" VALUES(50,'description','List of people who put this site together',NULL,NULL);
INSERT INTO "Node" VALUES(51,'title','Credits',NULL,NULL);
INSERT INTO "Node" VALUES(52,'content','creditspage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(53,'slug','credits',NULL,NULL);
INSERT INTO "Node" VALUES(54,'order','50',NULL,NULL);
INSERT INTO "Node" VALUES(55,'scorespage',NULL,6,1);
INSERT INTO "Node" VALUES(56,'page',NULL,NULL,1);
INSERT INTO "Node" VALUES(57,'highScores',NULL,7,7);
INSERT INTO "Node" VALUES(58,'description','High scores and ranking for players',NULL,NULL);
INSERT INTO "Node" VALUES(59,'player_ranks',NULL,NULL,8);
INSERT INTO "Node" VALUES(60,'puzzleuploadpage',NULL,8,1);
INSERT INTO "Node" VALUES(61,'page',NULL,NULL,1);
INSERT INTO "Node" VALUES(62,'description','Create custom puzzles by uploading a picture',NULL,NULL);
INSERT INTO "Node" VALUES(63,'puzzlepage',NULL,9,1);
INSERT INTO "Node" VALUES(64,'page',NULL,NULL,1);
INSERT INTO "Node" VALUES(65,'description','puzzle assembly',NULL,NULL);
INSERT INTO "Node" VALUES(66,'puzzle',NULL,NULL,9);
INSERT INTO "Node" VALUES(67,'pieces',NULL,NULL,1);
INSERT INTO "Node" VALUES(68,'puzzle_files',NULL,NULL,11);
INSERT INTO "Node" VALUES(69,'positions',NULL,NULL,10);
INSERT INTO "Node" VALUES(70,'timestamp',NULL,NULL,12);
INSERT INTO "Node" VALUES(71,'parent_of_top_left',NULL,NULL,13);
INSERT INTO "Node" VALUES(72,'preview_full',NULL,NULL,14);
INSERT INTO "Node" VALUES(73,'profilepage',NULL,10,1);
INSERT INTO "Node" VALUES(74,'player',NULL,NULL,15);
INSERT INTO "Node" VALUES(75,'puzzles',NULL,NULL,16);
INSERT INTO "Node" VALUES(76,'queuepage',NULL,11,1);
INSERT INTO "Node" VALUES(77,'puzzles',NULL,NULL,17);
INSERT INTO "Node" VALUES(79,'route',NULL,NULL,19);
INSERT INTO "Node" VALUES(80,'args',NULL,NULL,21);
INSERT INTO "Node" VALUES(81,'biticonspartial',NULL,12,22);
INSERT INTO "Node" VALUES(82,'artist_martin_berube_bit_icons',NULL,13,NULL);
INSERT INTO "Node" VALUES(83,'artist_mackenzie_deragon_bit_icons',NULL,14,NULL);
INSERT INTO "Node" VALUES(84,'contributorapplicationpage',NULL,5,1);
INSERT INTO "Node" VALUES(85,'description','Application for being a jigsaw puzzle contributor',NULL,NULL);
INSERT INTO "Node" VALUES(86,'content','contributorapplication-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(87,'title','Application for being a contributor',NULL,NULL);
INSERT INTO "Node" VALUES(88,'route',NULL,NULL,23);
INSERT INTO "Node" VALUES(89,'info',NULL,NULL,24);
INSERT INTO "Node" VALUES(90,'title','Questions and Answers',NULL,NULL);
INSERT INTO "Node" VALUES(91,'positions',NULL,5,1);
INSERT INTO "Node" VALUES(92,'content','positions-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(93,'description','List of available open positions.  These are all volunteer positions.',NULL,NULL);
INSERT INTO "Node" VALUES(94,'title','Volunteer Positions',NULL,NULL);
INSERT INTO "Node" VALUES(95,'recent_puzzles',NULL,NULL,25);
INSERT INTO "Node" VALUES(96,'homepage',NULL,1,1);
INSERT INTO "Node" VALUES(97,'page',NULL,NULL,1);
INSERT INTO "Node" VALUES(98,'description',' Massively Multiplayer Online Jigsaw Puzzles',NULL,NULL);
INSERT INTO "Node" VALUES(99,'content','frontpage-content.html',NULL,NULL);
INSERT INTO "Node" VALUES(103,'info',NULL,NULL,27);
INSERT INTO "Node" VALUES(107,'api_front_for_puzzle_id',NULL,15,1);
INSERT INTO "Node" VALUES(108,'puzzle_id',NULL,NULL,31);
INSERT INTO "Node" VALUES(109,'queuepage',NULL,11,1);
INSERT INTO "Node" VALUES(110,'puzzles',NULL,NULL,32);
INSERT INTO "Node" VALUES(111,'recent_puzzles',NULL,NULL,33);
INSERT INTO "Node" VALUES(112,'admin_puzzle_page',NULL,16,1);
INSERT INTO "Node" VALUES(113,'admin_puzzle_menu',NULL,NULL,1);
INSERT INTO "Node" VALUES(114,'puzzle_status_count',NULL,NULL,34);
INSERT INTO "Node" VALUES(117,'puzzles',NULL,NULL,36);
INSERT INTO "Node" VALUES(118,'admin_puzzle_page_all',NULL,16,1);
INSERT INTO "Node" VALUES(119,'admin_puzzle_page_submitted',NULL,16,1);
INSERT INTO "Node" VALUES(120,'puzzles',NULL,NULL,37);
INSERT INTO "Node" VALUES(121,'admin_puzzle_page_renderqueue',NULL,16,1);
INSERT INTO "Node" VALUES(122,'puzzles',NULL,NULL,38);
COMMIT;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Node_Node (
    node_id integer,
    target_node_id integer,
    foreign key ( node_id ) references Node ( id ) on delete cascade,
    foreign key ( target_node_id ) references Node ( id ) on delete cascade
);
INSERT INTO "Node_Node" VALUES(2,3);
INSERT INTO "Node_Node" VALUES(1,2);
INSERT INTO "Node_Node" VALUES(2,4);
INSERT INTO "Node_Node" VALUES(5,6);
INSERT INTO "Node_Node" VALUES(7,8);
INSERT INTO "Node_Node" VALUES(7,9);
INSERT INTO "Node_Node" VALUES(20,21);
INSERT INTO "Node_Node" VALUES(21,22);
INSERT INTO "Node_Node" VALUES(21,23);
INSERT INTO "Node_Node" VALUES(21,24);
INSERT INTO "Node_Node" VALUES(20,25);
INSERT INTO "Node_Node" VALUES(25,26);
INSERT INTO "Node_Node" VALUES(25,27);
INSERT INTO "Node_Node" VALUES(25,28);
INSERT INTO "Node_Node" VALUES(20,33);
INSERT INTO "Node_Node" VALUES(33,34);
INSERT INTO "Node_Node" VALUES(33,35);
INSERT INTO "Node_Node" VALUES(33,36);
INSERT INTO "Node_Node" VALUES(25,37);
INSERT INTO "Node_Node" VALUES(33,38);
INSERT INTO "Node_Node" VALUES(21,39);
INSERT INTO "Node_Node" VALUES(25,40);
INSERT INTO "Node_Node" VALUES(33,41);
INSERT INTO "Node_Node" VALUES(21,42);
INSERT INTO "Node_Node" VALUES(20,43);
INSERT INTO "Node_Node" VALUES(43,44);
INSERT INTO "Node_Node" VALUES(43,45);
INSERT INTO "Node_Node" VALUES(43,46);
INSERT INTO "Node_Node" VALUES(43,47);
INSERT INTO "Node_Node" VALUES(43,48);
INSERT INTO "Node_Node" VALUES(20,49);
INSERT INTO "Node_Node" VALUES(49,50);
INSERT INTO "Node_Node" VALUES(49,51);
INSERT INTO "Node_Node" VALUES(49,52);
INSERT INTO "Node_Node" VALUES(49,53);
INSERT INTO "Node_Node" VALUES(49,54);
INSERT INTO "Node_Node" VALUES(56,57);
INSERT INTO "Node_Node" VALUES(55,56);
INSERT INTO "Node_Node" VALUES(56,58);
INSERT INTO "Node_Node" VALUES(61,62);
INSERT INTO "Node_Node" VALUES(60,61);
INSERT INTO "Node_Node" VALUES(63,64);
INSERT INTO "Node_Node" VALUES(64,65);
INSERT INTO "Node_Node" VALUES(63,66);
INSERT INTO "Node_Node" VALUES(63,68);
INSERT INTO "Node_Node" VALUES(67,69);
INSERT INTO "Node_Node" VALUES(67,70);
INSERT INTO "Node_Node" VALUES(63,71);
INSERT INTO "Node_Node" VALUES(63,72);
INSERT INTO "Node_Node" VALUES(73,74);
INSERT INTO "Node_Node" VALUES(73,75);
INSERT INTO "Node_Node" VALUES(76,77);
INSERT INTO "Node_Node" VALUES(76,79);
INSERT INTO "Node_Node" VALUES(63,80);
INSERT INTO "Node_Node" VALUES(84,85);
INSERT INTO "Node_Node" VALUES(84,86);
INSERT INTO "Node_Node" VALUES(84,87);
INSERT INTO "Node_Node" VALUES(60,88);
INSERT INTO "Node_Node" VALUES(2,89);
INSERT INTO "Node_Node" VALUES(21,90);
INSERT INTO "Node_Node" VALUES(91,92);
INSERT INTO "Node_Node" VALUES(91,93);
INSERT INTO "Node_Node" VALUES(91,94);
INSERT INTO "Node_Node" VALUES(76,95);
INSERT INTO "Node_Node" VALUES(96,97);
INSERT INTO "Node_Node" VALUES(97,98);
INSERT INTO "Node_Node" VALUES(97,99);
INSERT INTO "Node_Node" VALUES(97,103);
INSERT INTO "Node_Node" VALUES(107,5);
INSERT INTO "Node_Node" VALUES(107,7);
INSERT INTO "Node_Node" VALUES(107,108);
INSERT INTO "Node_Node" VALUES(109,79);
INSERT INTO "Node_Node" VALUES(109,110);
INSERT INTO "Node_Node" VALUES(109,111);
INSERT INTO "Node_Node" VALUES(112,113);
INSERT INTO "Node_Node" VALUES(113,114);
INSERT INTO "Node_Node" VALUES(118,113);
INSERT INTO "Node_Node" VALUES(118,117);
INSERT INTO "Node_Node" VALUES(119,113);
INSERT INTO "Node_Node" VALUES(119,120);
INSERT INTO "Node_Node" VALUES(121,113);
INSERT INTO "Node_Node" VALUES(121,122);
COMMIT;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Query (
    id integer primary key,
    name varchar(255) not null
);
INSERT INTO "Query" VALUES(1,'select_link_node_from_node.sql');
INSERT INTO "Query" VALUES(2,'_select-frontpage-gallery-preview_full.sql');
INSERT INTO "Query" VALUES(3,'_select-frontpage-preview.sql');
INSERT INTO "Query" VALUES(4,'_recent-timeline-for-puzzle.sql');
INSERT INTO "Query" VALUES(6,'_select-queue-preview_full.sql');
INSERT INTO "Query" VALUES(7,'_select-high-scores.sql');
INSERT INTO "Query" VALUES(8,'_select-player-ranks.sql');
INSERT INTO "Query" VALUES(9,'_select-puzzle-by-puzzle_id.sql');
INSERT INTO "Query" VALUES(10,'_select-piece-by-puzzle_id.sql');
INSERT INTO "Query" VALUES(11,'_select-puzzle-resources-by-puzzle_id.sql');
INSERT INTO "Query" VALUES(12,'_select-timestamp-now.sql');
INSERT INTO "Query" VALUES(13,'_select-puzzle-piece-top-left-parent.sql');
INSERT INTO "Query" VALUES(14,'_select-puzzle-resources-preview_full-by-puzzle_id.sql');
INSERT INTO "Query" VALUES(15,'_select-player-for-profile.sql');
INSERT INTO "Query" VALUES(16,'_select-puzzles-for-profile.sql');
INSERT INTO "Query" VALUES(17,'_select-puzzles-for-queue--active.sql');
INSERT INTO "Query" VALUES(18,'_select-count-active-puzzles-for-queue.sql');
INSERT INTO "Query" VALUES(19,'_select-queuepage-offset.sql');
INSERT INTO "Query" VALUES(21,'_select-args-for-puzzlepage.sql');
INSERT INTO "Query" VALUES(22,'_select-iconname-for-route.sql');
INSERT INTO "Query" VALUES(23,'_select-args-for-uploadpage.sql');
INSERT INTO "Query" VALUES(24,'_frontpage-page-info-for-puzzle_id.sql');
INSERT INTO "Query" VALUES(25,'_select-recent_puzzles-for-queue--active.sql');
INSERT INTO "Query" VALUES(26,'_select-homepage-gallery-preview_full.sql');
INSERT INTO "Query" VALUES(27,'_homepage-page-info-for-most-recent-active-puzzle.sql');
INSERT INTO "Query" VALUES(29,'_select-homepage-preview.sql');
INSERT INTO "Query" VALUES(30,'_select-homepage-puzzle_id.sql');
INSERT INTO "Query" VALUES(31,'_route-pass-puzzle_id.sql');
INSERT INTO "Query" VALUES(32,'_select-puzzles-for-queue--complete.sql');
INSERT INTO "Query" VALUES(33,'_select-recent_puzzles-for-queue--complete.sql');
INSERT INTO "Query" VALUES(34,'_select-puzzle-status-count.sql');
INSERT INTO "Query" VALUES(35,'_select-puzzle-count-for-needs-moderation.sql');
INSERT INTO "Query" VALUES(36,'_select-admin-puzzles-all.sql');
INSERT INTO "Query" VALUES(37,'_select-admin-puzzles-needs-moderation.sql');
INSERT INTO "Query" VALUES(38,'_select-admin-puzzles-render.sql');
COMMIT;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Route (
    id integer primary key,
    path text not null,
    node_id integer,
    weight integer default 0,
    method varchar(10) default 'GET',
    foreign key ( node_id ) references Node ( id ) on delete set null
);
INSERT INTO "Route" VALUES(1,'/front/<puzzle_id>/',1,'','GET');
INSERT INTO "Route" VALUES(2,'/front/',96,'','GET');
INSERT INTO "Route" VALUES(3,'/faq/',21,'','GET');
INSERT INTO "Route" VALUES(4,'/contact/',25,'','GET');
INSERT INTO "Route" VALUES(5,'/about/',33,'','GET');
INSERT INTO "Route" VALUES(6,'/help/',43,'','GET');
INSERT INTO "Route" VALUES(7,'/credits/',49,'','GET');
INSERT INTO "Route" VALUES(8,'/high-scores/',55,'','GET');
INSERT INTO "Route" VALUES(9,'/api/player-ranks/',59,'','GET');
INSERT INTO "Route" VALUES(12,'/api/puzzle-pieces/<puzzle_id>/',67,'','GET');
INSERT INTO "Route" VALUES(13,'/player/<login>/',73,'','GET');
INSERT INTO "Route" VALUES(14,'/player/',73,'','GET');
INSERT INTO "Route" VALUES(15,'/queue/<any(''active''):status>/<any(''0''):offset>/',76,'','GET');
INSERT INTO "Route" VALUES(16,'/bit-icons/<iconname>/',81,'','GET');
INSERT INTO "Route" VALUES(17,'/artist/martin-berube/bit-icons/',82,'','GET');
INSERT INTO "Route" VALUES(18,'/artist/mackenzie-deragon/bit-icons/',83,'','GET');
INSERT INTO "Route" VALUES(19,'/contributor-application/',84,'','GET');
INSERT INTO "Route" VALUES(20,'/new-puzzle/<contributor>/',60,'','GET');
INSERT INTO "Route" VALUES(21,'/positions/',91,'','GET');
INSERT INTO "Route" VALUES(22,'/api/front/<puzzle_id>/',107,'','GET');
INSERT INTO "Route" VALUES(23,'/puzzle/<puzzle_id>/scale/<int:scale>/',63,'','GET');
INSERT INTO "Route" VALUES(24,'/queue/<any(''complete''):status>/<any(''0''):offset>/',109,'','GET');
INSERT INTO "Route" VALUES(25,'/admin/puzzle/',112,1,'GET');
INSERT INTO "Route" VALUES(26,'/admin/puzzle/all/',118,'','GET');
INSERT INTO "Route" VALUES(27,'/admin/puzzle/submitted/',119,'','GET');
INSERT INTO "Route" VALUES(28,'/admin/puzzle/renderqueue/',121,'','GET');
COMMIT;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Template (
    id integer primary key,
    name varchar(255) unique not null
);
INSERT INTO "Template" VALUES(1,'front.html');
INSERT INTO "Template" VALUES(2,'gallery.html');
INSERT INTO "Template" VALUES(3,'preview.html');
INSERT INTO "Template" VALUES(4,'queue.html');
INSERT INTO "Template" VALUES(5,'docs.html');
INSERT INTO "Template" VALUES(6,'scorespage.html');
INSERT INTO "Template" VALUES(7,'highScores.html');
INSERT INTO "Template" VALUES(8,'puzzleuploadpage.html');
INSERT INTO "Template" VALUES(9,'puzzlepage.html');
INSERT INTO "Template" VALUES(10,'profilepage.html');
INSERT INTO "Template" VALUES(11,'queuepage.html');
INSERT INTO "Template" VALUES(12,'bit-icons-img.html');
INSERT INTO "Template" VALUES(13,'credit-bit-icons-for-martin-berube.html');
INSERT INTO "Template" VALUES(14,'credit-bit-icons-for-mackenzie-deragon.html');
INSERT INTO "Template" VALUES(15,'frontpage.html');
INSERT INTO "Template" VALUES(16,'admin-puzzlepage.html');
COMMIT;