--
-- Create a recursive function to grab all values from a jsonb document except for booleans and strings that are uuids
--
CREATE OR REPLACE FUNCTION jsonb_descriptor(jsonValue JSONB)
RETURNS TEXT AS
$$
DECLARE
  docStr TEXT := '';
  subValue JSONB;
BEGIN
  CASE jsonb_typeof(jsonValue)
  WHEN 'null' THEN docStr := ''; -- uuids are not interesting
  WHEN 'boolean' THEN docStr := ''; -- booleans are not interesting
  WHEN 'number' THEN docStr := jsonValue::TEXT;
  WHEN 'string' THEN
    BEGIN
      docStr := jsonb_build_array(jsonValue) ->> 0;
      IF uuid(docStr) IS NOT NULL THEN
        docStr := ''; -- uuids are not interesting
      END IF;
      EXCEPTION
        WHEN OTHERS THEN docStr := docStr;
      END;
  WHEN 'array' THEN
    FOR subValue IN SELECT value FROM jsonb_array_elements(jsonValue)
    LOOP
      docStr := docStr || jsonb_descriptor(subValue) || ' ';
    END LOOP;
  ELSE -- Must be object
    FOR subValue IN SELECT value FROM jsonb_each(jsonValue)
    LOOP
      docStr := docStr || jsonb_descriptor(subValue) || ' ';
    END LOOP;
  END CASE;
    
  RETURN trim(docStr);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

--
-- Create table for all documents
--
CREATE TABLE IF NOT EXISTS DOCS(
  doc JSONB,
  id UUID GENERATED ALWAYS AS (uuid(doc ->> 'id')) STORED,
  parentId UUID GENERATED ALWAYS AS (uuid(doc ->> 'parentId')) STORED,
  descriptor TSVECTOR GENERATED ALWAYS AS (to_tsvector(
    'simple',
    CASE WHEN doc ? 'descriptor' THEN doc ->> 'descriptor' ELSE jsonb_descriptor(doc) END
  )) STORED,
  PRIMARY KEY (id),
  FOREIGN KEY (parentId) REFERENCES DOCS(id),
  CHECK (id != parentId),
  CHECK ((doc ? 'type') AND (jsonb_typeof(doc -> 'type') = 'string'))
);

--
-- Create jsonb_path_ops index on docs.doc
--
CREATE INDEX IF NOT EXISTS docs_ix_doc ON DOCS USING GIN(doc jsonb_path_ops);

--
-- Create full text search index on docs.descriptor
--
CREATE INDEX IF NOT EXISTS docs_ix_descriptor ON DOCS USING GIN(descriptor);

--
-- Generate data, if the table is empty
--
DO $$
DECLARE
BEGIN
  IF NOT EXISTS (SELECT FROM docs) THEN
    WITH firstNames AS (
      SELECT ARRAY[
        'Jane', 'Sarah', 'Christy', 'Deborah', 'Jen',
        'John', 'Thomas', 'James', 'Jason', 'Kevin'
      ] firstNames
    ),
    lastNames AS (
      SELECT ARRAY[
        'Jameson', 'Dickinson', 'Lee', 'Wong', 'Smith',
        'Donson', 'Myers', 'MacVeigh', 'King', 'Costner'
      ] lastNames
    ),
    addresses AS (
      SELECT ARRAY[
        ['796 Jones Drive', 'Beaumont', 'AB', 'CAN', 'T4X 4N5'],
        ['28 West Street', 'Torbay', 'NL', 'CAN', 'A1K 9H6'],
        ['688 Sulphur Springs Ave', 'Mississauga', 'ON', 'CAN', 'L4T 7B0'],
        ['517 Bishop Road', 'Stouffville', 'ON', 'CAN', 'L4A 0J2'],
        ['9718 4th St', 'Laurentides-Sud', 'QC', 'CAN',  'J0V 0H7'],
        ['347 Glenridge St', 'Athabasca', 'AB', 'CAN', 'T9S 4R9']
      ] addresses
    )
    INSERT INTO docs(doc)
    SELECT jsonb_build_object(
      'type', 'Customer',
      'id', gen_random_uuid(),
      'firstName', firstNames[firstNamesIdx],
      'lastName', lastNames[lastNamesIdx],
      'address', jsonb_build_object(
        'line', addresses[addressRow][1],
        'city', addresses[addressRow][2],
        'region', addresses[addressRow][3],
        'country', addresses[addressRow][4],
        'mailCode', addresses[addressRow][5]
      ),
      'descriptor', firstNames[firstNamesIdx] || ' ' ||
                    lastNames[lastNamesIdx] || ' ' ||
                    addresses[addressRow][2] || ' ' ||
                    addresses[addressRow][3]  
    )
    FROM firstNames,
         lastNames,
         addresses,
         ( SELECT ceil(random() * array_length(firstNames, 1)) firstNamesIdx,
                  ceil(random() * array_length(lastNames, 1)) lastNamesIdx,
                  ceil(random() * array_length(addresses, 1)) addressRow
             FROM firstNames,
                  lastNames,
                  addresses,
                  generate_series(1, 1000000)
      ) t;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Update query planning info
ANALYZE docs;

-- Time some queries
\timing

SELECT count(*)
  FROM docs
 WHERE doc @> jsonb_build_object('firstName', 'Jane', 'address', jsonb_build_object('city', 'ON'));

SELECT count(*)
  FROM docs
 WHERE doc @> jsonb_build_object('firstName', 'Bob', 'address', jsonb_build_object('city', 'ON'));

SELECT count(*)
  FROM docs
 WHERE descriptor @@ 'jane & on';
 
SELECT count(*)
  FROM docs
 WHERE descriptor @@ 'bob & on';

-- Upsert query example

INSERT INTO docs(doc) VALUES(
  jsonb_build_object(
    'id', '12345678-1234-1234-1234-1234567890AB',
    'type', 'UpsertTest',
    'foo', 'bar'
  )
) ON CONFLICT (id) DO
UPDATE SET doc = jsonb_build_object(
  'id', '12345678-1234-1234-1234-1234567890AB',
  'type', 'UpsertTest',
  'foo', 'barish'
);

SELECT doc from docs where descriptor @@ 'upserttest & bar';

INSERT INTO docs(doc) VALUES(
  jsonb_build_object(
    'id', '12345678-1234-1234-1234-1234567890AB',
    'type', 'UpsertTest',
    'foo', 'bar'
  )
) ON CONFLICT (id) DO
UPDATE SET doc = jsonb_build_object(
  'id', '12345678-1234-1234-1234-1234567890AB',
  'type', 'UpsertTest',
  'foo', 'barish'
);

SELECT doc from docs where descriptor @@ 'upserttest & barish';

\timing
