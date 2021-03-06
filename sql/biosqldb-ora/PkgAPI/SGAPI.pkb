-- -*-Sql-*- mode (to keep my emacs happy)
--
-- API Package body for general or special purpose SymGene functions and
-- procedures.
--
-- $GNF: projects/gi/symgene/src/DB/PkgAPI/SGAPI.pkb,v 1.5 2003/06/11 10:03:20 hlapp Exp $
--

--
-- Copyright 2002-2003 Genomics Institute of the Novartis Research Foundation
-- Copyright 2002-2008 Hilmar Lapp
-- 
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

CREATE OR REPLACE
PACKAGE BODY SGAPI IS

FUNCTION Platonic_Ent(Ent_Oid IN SG_Bioentry.Oid%TYPE)
RETURN SG_Bioentry.Oid%TYPE
IS
BEGIN
	RETURN EntA.Platonic_Ent(Ent_Oid);
END;

FUNCTION Ent_Descendants(
			Ent_Oid		IN SG_Bioentry.Oid%TYPE,
		 	Trm_Oid		IN SG_Term.Oid%TYPE DEFAULT NULL,
			Trm_Name	IN SG_Term.Name%TYPE DEFAULT NULL,
			Trm_Identifier IN SG_Term.Identifier%TYPE DEFAULT NULL,
			Ont_Oid		IN SG_Ontology.Oid%TYPE DEFAULT NULL,
			Ont_Name	IN SG_Ontology.Name%TYPE DEFAULT NULL)
RETURN Oid_List_t
IS
BEGIN
	RETURN EntA.Ent_Descendants(
			Ent_Oid		=> Ent_Oid,
		 	Trm_Oid		=> Trm_Oid,
			Trm_Name	=> Trm_Name,
			Trm_Identifier  => Trm_Identifier,
			Ont_Oid		=> Ont_Oid,
			Ont_Name	=> Ont_Name);
END;

PROCEDURE delete_mapping(
		Asm_Name	IN SG_Biodatabase.Name%TYPE,
		DB_Name		IN SG_Biodatabase.Name%TYPE DEFAULT NULL,
		FSrc_Name	IN SG_Term.Name%TYPE DEFAULT NULL)
IS
BEGIN
	ChrEntA.delete_mapping(Asm_Name  => Asm_Name,
			       DB_Name   => DB_Name,
			       FSrc_Name => FSrc_Name);
END;


END SGAPI;
/
