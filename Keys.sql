--Returns all tables in a database, the primary and foreign keys for those tables, the tables and columns referenced by the foreign keys, and the datatype of the columns
--This is particularly useful when working against a linked server you can't see the relationships in
--if running against a linked server replace all [REPLACE] with the linked server and database name like LinkedServer.Database
--if running on the database itself replace all [REPLACE]. with nothing

SELECT
    dt1.object_id AS 'ObjectID'
    ,dt1.name AS 'TableName'
    ,dt2.KeyType
    ,dt2.KeyName
    ,dt2.ColumnName
    ,dt2.DataType
    ,dt2.max_length
    ,dt2.Precision
    ,dt2.Scale
    ,dt2.ReferencedColumn
FROM
    (
    SELECT *
    FROM [REPLACE].sys.tables t
    WHERE t.type='U'
    )dt1
LEFT JOIN
    (
    SELECT
        t.object_id AS 'ObjectID'
        ,t.name AS 'TableName'
        ,'Primary' AS 'KeyType'
        ,i.name AS 'KeyName'
        ,c.name AS 'ColumnName'
        ,ty.name AS 'DataType'
        ,ty.max_length
        ,CASE
            WHEN ty.name='Decimal' THEN CAST(ty.precision AS VARCHAR(50))
            ELSE ''
        END AS 'Precision'
        ,CASE
            WHEN ty.name='Decimal' THEN CAST(ty.scale AS VARCHAR(50))
            ELSE ''
        END AS 'Scale'
        ,'' AS 'ReferencedColumn'
    FROM [REPLACE].sys.tables t
    JOIN [REPLACE].sys.indexes i ON (t.object_id=i.object_id)
    JOIN [REPLACE].sys.index_columns ic ON ((i.object_id=ic.object_id)AND(i.index_id=ic.index_id))
    JOIN [REPLACE].sys.columns c ON ((i.object_id=c.object_id)AND(ic.column_id=c.column_id))
    JOIN [REPLACE].sys.types ty ON (c.user_type_id=ty.user_type_id)
    WHERE t.type='U'
    AND i.is_primary_key=1

    UNION ALL

    SELECT
        t.object_id AS 'ObjectID'
        ,t.name AS 'TableName'
        ,'Foreign' AS 'KeyType'
        ,k.name AS 'KeyName'
        ,c.name AS 'ColumnName'
        ,ty.name AS 'DataType'
        ,ty.max_length
        ,CASE
            WHEN ty.name='Decimal' THEN CAST(ty.precision AS VARCHAR(50))
            ELSE ''
        END AS 'Precision'
        ,CASE
            WHEN ty.name='Decimal' THEN CAST(ty.scale AS VARCHAR(50))
            ELSE ''
        END AS 'Scale'
        ,t2.name + '.' + c2.name AS 'ReferencedColumn'
    FROM [REPLACE].sys.tables t
    JOIN [REPLACE].sys.foreign_keys k ON (t.object_id=k.parent_object_id)
    JOIN [REPLACE].sys.foreign_key_columns kc ON (k.object_id=kc.constraint_object_id)
    JOIN [REPLACE].sys.columns c ON ((kc.parent_object_id=c.object_id)AND(kc.parent_column_id=c.column_id))
    JOIN [REPLACE].sys.types ty ON (c.user_type_id=ty.user_type_id)
    JOIN [REPLACE].sys.columns c2 ON ((kc.referenced_object_id=c2.object_id)AND(kc.referenced_column_id=c2.column_id))
    JOIN [REPLACE].sys.tables t2 ON (c2.object_id=t2.object_id)
    WHERE t.type='U'
    )dt2 ON (dt1.object_id=dt2.ObjectID)
ORDER BY dt1.name ASC,
    CASE
        WHEN dt2.KeyType='Primary' THEN 1
        WHEN dt2.KeyType='Foreign' THEN 2
    END ASC;
