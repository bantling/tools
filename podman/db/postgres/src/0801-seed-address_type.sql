-- Seed address types
INSERT INTO tables.address_type(
   id
  ,name
  ,ord
) VALUES
  (
     '27BC4BBF-42B3-4957-BC33-441A94AA9F43'::UUID
    ,'Physical'
    ,1
  ),
  (
     '3DD2ACE7-D46C-42E7-86CB-2414574067A1'::UUID
    ,'Mailing'
    ,2
  ),
  (
     'A6370032-E2C3-43A2-ACB3-E3DAEF3B4F3D'::UUID
    ,'Billing'
    ,3
  );