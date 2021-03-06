-- $Id$
--
-- Copyright 2002-2003 Ewan Birney, Elia Stupka, Chris Mungall
-- Copyright 2003-2008 Hilmar Lapp
-- Copyright 2018 Nithin Saripalli
--  This file is part of BioSQL.
--
--  BioSQL is free software: you can redistribute it and/or modify it
--  under the terms of the GNU Lesser General Public License as
--  published by the Free Software Foundation, either version 3 of the
--  License, or (at your option) any later version.
--
--  BioSQL is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Lesser General Public License for more details.
--
--  You should have received a copy of the GNU Lesser General Public License
--  along with BioSQL. If not, see <http://www.gnu.org/licenses/>.
--
-- ========================================================================
--
-- Authors: Ewan Birney, Elia Stupka, Hilmar Lapp, Aaron Mackey
-- Post-Cape Town changes by Hilmar Lapp.
-- Singapore changes by Hilmar Lapp and Aaron Mackey.
-- Migration of the MySQL schema to InnoDB by Hilmar Lapp
--
-- comments to biosql - biosql-l@open-bio.org

-- conventions:
-- <table_name>_id is primary internal id (usually autogenerated)
--
-- Certain definitions in this schema, in particular certain unique
-- key constrain definitions, are optional, or may optionally be
-- changed (customized, if you wil). Search for the word OPTION: in
-- capital letters.
--
-- Note that some aspects of the schema like uniqueness constraints
-- may be changed to best suit your requirements. Search for the tag
-- CONFIG and read the documentation you find there.
--

-- database have bioentries. That is about it.
-- we do not store different versions of a database as different dbids
-- (there is no concept of versions of database). There is a concept of
-- versions of entries. Versions of databases deserve their own table and
-- join to bioentry table for tracking with versions of entries

create table if not exists biodatabase
(
  biodatabase_id int unsigned auto_increment
    primary key,
  name           varchar(128) not null,
  authority      varchar(128) null,
  description    text         null,
  constraint name
  unique (name)
)
  charset = latin1;

create index db_auth
  on biodatabase (authority);

create table if not exists dbxref
(
  dbxref_id int unsigned auto_increment
    primary key,
  dbname    varchar(40)          not null,
  accession varchar(128)         not null,
  version   smallint(5) unsigned not null,
  constraint accession
  unique (accession, dbname, version)
)
  charset = latin1;

create index dbxref_db
  on dbxref (dbname);

create table if not exists ontology
(
  ontology_id int unsigned auto_increment
    primary key,
  name        varchar(32) not null,
  definition  text        null,
  constraint name
  unique (name)
)
  charset = latin1;

create table if not exists reference
(
  reference_id int unsigned auto_increment
    primary key,
  dbxref_id    int unsigned null,
  location     text         not null,
  title        text         null,
  authors      text         null,
  crc          varchar(32)  null,
  constraint crc
  unique (crc),
  constraint dbxref_id
  unique (dbxref_id),
  constraint FKdbxref_reference
  foreign key (dbxref_id) references dbxref (dbxref_id)
)
  charset = latin1;

create table if not exists taxon
(
  taxon_id          int unsigned auto_increment
    primary key,
  ncbi_taxon_id     int(10)          null,
  parent_taxon_id   int unsigned     null,
  node_rank         varchar(32)      null,
  genetic_code      tinyint unsigned null,
  mito_genetic_code tinyint unsigned null,
  left_value        int unsigned     null,
  right_value       int unsigned     null,
  constraint left_value
  unique (left_value),
  constraint ncbi_taxon_id
  unique (ncbi_taxon_id),
  constraint right_value
  unique (right_value)
)
  charset = latin1;

create table if not exists bioentry
(
  bioentry_id    int unsigned auto_increment
    primary key,
  biodatabase_id int unsigned         not null,
  taxon_id       int unsigned         null,
  name           varchar(40)          not null,
  accession      varchar(128)         not null,
  identifier     varchar(40)          null,
  division       varchar(6)           null,
  description    text                 null,
  version        smallint(5) unsigned not null,
  constraint accession
  unique (accession, biodatabase_id, version),
  constraint identifier
  unique (identifier, biodatabase_id),
  constraint FKbiodatabase_bioentry
  foreign key (biodatabase_id) references biodatabase (biodatabase_id),
  constraint FKtaxon_bioentry
  foreign key (taxon_id) references taxon (taxon_id)
)
  charset = latin1;

create index bioentry_db
  on bioentry (biodatabase_id);

create index bioentry_name
  on bioentry (name);

create index bioentry_tax
  on bioentry (taxon_id);

create table if not exists bioentry_dbxref
(
  bioentry_id int unsigned not null,
  dbxref_id   int unsigned not null,
  rank        smallint(6)  null,
  primary key (bioentry_id, dbxref_id),
  constraint FKbioentry_dblink
  foreign key (bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKdbxref_dblink
  foreign key (dbxref_id) references dbxref (dbxref_id)
    on delete cascade
)
  charset = latin1;

create index dblink_dbx
  on bioentry_dbxref (dbxref_id);

create table if not exists bioentry_reference
(
  bioentry_id  int unsigned            not null,
  reference_id int unsigned            not null,
  start_pos    int(10)                 null,
  end_pos      int(10)                 null,
  rank         smallint(6) default '0' not null,
  primary key (bioentry_id, reference_id, rank),
  constraint FKbioentry_entryref
  foreign key (bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKreference_entryref
  foreign key (reference_id) references reference (reference_id)
    on delete cascade
)
  charset = latin1;

create index bioentryref_ref
  on bioentry_reference (reference_id);

create table if not exists biosequence
(
  bioentry_id int unsigned not null
    primary key,
  version     smallint(6)  null,
  length      int(10)      null,
  alphabet    varchar(10)  null,
  seq         longtext     null,
  constraint FKbioentry_bioseq
  foreign key (bioentry_id) references bioentry (bioentry_id)
    on delete cascade
)
  charset = latin1;

create table if not exists comment
(
  comment_id   int unsigned auto_increment
    primary key,
  bioentry_id  int unsigned            not null,
  comment_text text                    not null,
  rank         smallint(6) default '0' not null,
  constraint bioentry_id
  unique (bioentry_id, rank),
  constraint FKbioentry_comment
  foreign key (bioentry_id) references bioentry (bioentry_id)
    on delete cascade
)
  charset = latin1;

create index taxparent
  on taxon (parent_taxon_id);

create table if not exists taxon_name
(
  taxon_id   int unsigned not null,
  name       varchar(255) not null,
  name_class varchar(32)  not null,
  constraint taxon_id
  unique (taxon_id, name, name_class),
  constraint FKtaxon_taxonname
  foreign key (taxon_id) references taxon (taxon_id)
    on delete cascade
)
  charset = latin1;

create index taxnamename
  on taxon_name (name);

create index taxnametaxonid
  on taxon_name (taxon_id);

create table if not exists term
(
  term_id     int unsigned auto_increment
    primary key,
  name        varchar(255) not null,
  definition  text         null,
  identifier  varchar(40)  null,
  is_obsolete char         null,
  ontology_id int unsigned not null,
  constraint identifier
  unique (identifier),
  constraint name
  unique (name, ontology_id, is_obsolete),
  constraint FKont_term
  foreign key (ontology_id) references ontology (ontology_id)
    on delete cascade
)
  charset = latin1;

create table if not exists bioentry_path
(
  object_bioentry_id  int unsigned not null,
  subject_bioentry_id int unsigned not null,
  term_id             int unsigned not null,
  distance            int unsigned null,
  constraint object_bioentry_id
  unique (object_bioentry_id, subject_bioentry_id, term_id, distance),
  constraint FKchildent_bioentrypath
  foreign key (subject_bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKparentent_bioentrypath
  foreign key (object_bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKterm_bioentrypath
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index bioentrypath_child
  on bioentry_path (subject_bioentry_id);

create index bioentrypath_trm
  on bioentry_path (term_id);

create table if not exists bioentry_qualifier_value
(
  bioentry_id int unsigned       not null,
  term_id     int unsigned       not null,
  value       text               null,
  rank        int(5) default '0' not null,
  constraint bioentry_id
  unique (bioentry_id, term_id, rank),
  constraint FKbioentry_entqual
  foreign key (bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKterm_entqual
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index bioentryqual_trm
  on bioentry_qualifier_value (term_id);

create table if not exists bioentry_relationship
(
  bioentry_relationship_id int unsigned auto_increment
    primary key,
  object_bioentry_id       int unsigned not null,
  subject_bioentry_id      int unsigned not null,
  term_id                  int unsigned not null,
  rank                     int(5)       null,
  constraint object_bioentry_id
  unique (object_bioentry_id, subject_bioentry_id, term_id),
  constraint FKchildent_bioentryrel
  foreign key (subject_bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKparentent_bioentryrel
  foreign key (object_bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKterm_bioentryrel
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index bioentryrel_child
  on bioentry_relationship (subject_bioentry_id);

create index bioentryrel_trm
  on bioentry_relationship (term_id);

create table if not exists dbxref_qualifier_value
(
  dbxref_id int unsigned            not null,
  term_id   int unsigned            not null,
  rank      smallint(6) default '0' not null,
  value     text                    null,
  primary key (dbxref_id, term_id, rank),
  constraint FKdbxref_dbxrefqual
  foreign key (dbxref_id) references dbxref (dbxref_id)
    on delete cascade,
  constraint FKtrm_dbxrefqual
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index dbxrefqual_dbx
  on dbxref_qualifier_value (dbxref_id);

create index dbxrefqual_trm
  on dbxref_qualifier_value (term_id);

create table if not exists seqfeature
(
  seqfeature_id  int unsigned auto_increment
    primary key,
  bioentry_id    int unsigned                     not null,
  ENGINE_term_id int unsigned                     not null,
  source_term_id int unsigned                     not null,
  display_name   varchar(64)                      null,
  rank           smallint(5) unsigned default '0' not null,
  constraint bioentry_id
  unique (bioentry_id, ENGINE_term_id, source_term_id, rank),
  constraint FKbioentry_seqfeature
  foreign key (bioentry_id) references bioentry (bioentry_id)
    on delete cascade,
  constraint FKsourceterm_seqfeature
  foreign key (source_term_id) references term (term_id),
  constraint FKterm_seqfeature
  foreign key (ENGINE_term_id) references term (term_id)
)
  charset = latin1;

create table if not exists location
(
  location_id   int unsigned auto_increment
    primary key,
  seqfeature_id int unsigned            not null,
  dbxref_id     int unsigned            null,
  term_id       int unsigned            null,
  start_pos     int(10)                 null,
  end_pos       int(10)                 null,
  strand        tinyint default '0'     not null,
  rank          smallint(6) default '0' not null,
  constraint seqfeature_id
  unique (seqfeature_id, rank),
  constraint FKdbxref_location
  foreign key (dbxref_id) references dbxref (dbxref_id),
  constraint FKseqfeature_location
  foreign key (seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade,
  constraint FKterm_featloc
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index seqfeatureloc_dbx
  on location (dbxref_id);

create index seqfeatureloc_start
  on location (start_pos, end_pos);

create index seqfeatureloc_trm
  on location (term_id);

create table if not exists location_qualifier_value
(
  location_id int unsigned not null,
  term_id     int unsigned not null,
  value       varchar(255) not null,
  int_value   int(10)      null,
  primary key (location_id, term_id),
  constraint FKfeatloc_locqual
  foreign key (location_id) references location (location_id)
    on delete cascade,
  constraint FKterm_locqual
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index locationqual_trm
  on location_qualifier_value (term_id);

create index seqfeature_fsrc
  on seqfeature (source_term_id);

create index seqfeature_trm
  on seqfeature (ENGINE_term_id);

create table if not exists seqfeature_dbxref
(
  seqfeature_id int unsigned not null,
  dbxref_id     int unsigned not null,
  rank          smallint(6)  null,
  primary key (seqfeature_id, dbxref_id),
  constraint FKdbxref_feadblink
  foreign key (dbxref_id) references dbxref (dbxref_id)
    on delete cascade,
  constraint FKseqfeature_feadblink
  foreign key (seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade
)
  charset = latin1;

create index feadblink_dbx
  on seqfeature_dbxref (dbxref_id);

create table if not exists seqfeature_path
(
  object_seqfeature_id  int unsigned not null,
  subject_seqfeature_id int unsigned not null,
  term_id               int unsigned not null,
  distance              int unsigned null,
  constraint object_seqfeature_id
  unique (object_seqfeature_id, subject_seqfeature_id, term_id, distance),
  constraint FKchildfeat_seqfeatpath
  foreign key (subject_seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade,
  constraint FKparentfeat_seqfeatpath
  foreign key (object_seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade,
  constraint FKterm_seqfeatpath
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index seqfeaturepath_child
  on seqfeature_path (subject_seqfeature_id);

create index seqfeaturepath_trm
  on seqfeature_path (term_id);

create table if not exists seqfeature_qualifier_value
(
  seqfeature_id int unsigned            not null,
  term_id       int unsigned            not null,
  rank          smallint(6) default '0' not null,
  value         text                    not null,
  primary key (seqfeature_id, term_id, rank),
  constraint FKseqfeature_featqual
  foreign key (seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade,
  constraint FKterm_featqual
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index seqfeaturequal_trm
  on seqfeature_qualifier_value (term_id);

create table if not exists seqfeature_relationship
(
  seqfeature_relationship_id int unsigned auto_increment
    primary key,
  object_seqfeature_id       int unsigned not null,
  subject_seqfeature_id      int unsigned not null,
  term_id                    int unsigned not null,
  rank                       int(5)       null,
  constraint object_seqfeature_id
  unique (object_seqfeature_id, subject_seqfeature_id, term_id),
  constraint FKchildfeat_seqfeatrel
  foreign key (subject_seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade,
  constraint FKparentfeat_seqfeatrel
  foreign key (object_seqfeature_id) references seqfeature (seqfeature_id)
    on delete cascade,
  constraint FKterm_seqfeatrel
  foreign key (term_id) references term (term_id)
)
  charset = latin1;

create index seqfeaturerel_child
  on seqfeature_relationship (subject_seqfeature_id);

create index seqfeaturerel_trm
  on seqfeature_relationship (term_id);

create index term_ont
  on term (ontology_id);

create table if not exists term_dbxref
(
  term_id   int unsigned not null,
  dbxref_id int unsigned not null,
  rank      smallint(6)  null,
  primary key (term_id, dbxref_id),
  constraint FKdbxref_trmdbxref
  foreign key (dbxref_id) references dbxref (dbxref_id)
    on delete cascade,
  constraint FKterm_trmdbxref
  foreign key (term_id) references term (term_id)
    on delete cascade
)
  charset = latin1;

create index trmdbxref_dbxrefid
  on term_dbxref (dbxref_id);

create table if not exists term_path
(
  term_path_id      int unsigned auto_increment
    primary key,
  subject_term_id   int unsigned not null,
  predicate_term_id int unsigned not null,
  object_term_id    int unsigned not null,
  ontology_id       int unsigned not null,
  distance          int unsigned null,
  constraint subject_term_id
  unique (subject_term_id, predicate_term_id, object_term_id, ontology_id, distance),
  constraint FKontology_trmpath
  foreign key (ontology_id) references ontology (ontology_id)
    on delete cascade,
  constraint FKtrmobject_trmpath
  foreign key (object_term_id) references term (term_id)
    on delete cascade,
  constraint FKtrmpredicate_trmpath
  foreign key (predicate_term_id) references term (term_id)
    on delete cascade,
  constraint FKtrmsubject_trmpath
  foreign key (subject_term_id) references term (term_id)
    on delete cascade
)
  charset = latin1;

create index trmpath_objectid
  on term_path (object_term_id);

create index trmpath_ontid
  on term_path (ontology_id);

create index trmpath_predicateid
  on term_path (predicate_term_id);

create table if not exists term_relationship
(
  term_relationship_id int unsigned auto_increment
    primary key,
  subject_term_id      int unsigned not null,
  predicate_term_id    int unsigned not null,
  object_term_id       int unsigned not null,
  ontology_id          int unsigned not null,
  constraint subject_term_id
  unique (subject_term_id, predicate_term_id, object_term_id, ontology_id),
  constraint FKterm_trmrel
  foreign key (ontology_id) references ontology (ontology_id)
    on delete cascade,
  constraint FKtrmobject_trmrel
  foreign key (object_term_id) references term (term_id)
    on delete cascade,
  constraint FKtrmpredicate_trmrel
  foreign key (predicate_term_id) references term (term_id)
    on delete cascade,
  constraint FKtrmsubject_trmrel
  foreign key (subject_term_id) references term (term_id)
    on delete cascade
)
  charset = latin1;

create index trmrel_objectid
  on term_relationship (object_term_id);

create index trmrel_ontid
  on term_relationship (ontology_id);

create index trmrel_predicateid
  on term_relationship (predicate_term_id);

create table if not exists term_relationship_term
(
  term_relationship_id int unsigned not null
    primary key,
  term_id              int unsigned not null,
  constraint term_id
  unique (term_id),
  constraint FKtrm_trmreltrm
  foreign key (term_id) references term (term_id)
    on delete cascade,
  constraint FKtrmrel_trmreltrm
  foreign key (term_relationship_id) references term_relationship (term_relationship_id)
    on delete cascade
)
  charset = latin1;

create table if not exists term_synonym
(
  synonym varchar(255) not null,
  term_id int unsigned not null,
  primary key (term_id, synonym),
  constraint FKterm_syn
  foreign key (term_id) references term (term_id)
    on delete cascade
)
  charset = latin1;

