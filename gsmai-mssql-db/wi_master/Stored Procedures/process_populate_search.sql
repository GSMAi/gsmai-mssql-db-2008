
CREATE PROCEDURE [dbo].[process_populate_search]

AS

BEGIN
	-- Organisations with data
	INSERT INTO search (scheme_entity_id, entity_id, entity_type, term, metadata, [table], [order])
	SELECT	'organisations-' + CAST(o.id AS nvarchar),
			o.id,
			CASE o.type_id WHEN 9 THEN 'Group' ELSE 'Operator' END,
			o.name + CASE WHEN z.name IS NOT null THEN ', ' + z.name ELSE '' END,
			z.name,
			'organisations',
			2
			
	FROM	organisations o LEFT JOIN
			organisation_zone_link oz ON o.id = oz.organisation_id LEFT JOIN
			zones z ON oz.zone_id = z.id
			
	WHERE	o.id NOT IN (SELECT DISTINCT entity_id FROM search WHERE [table] = 'organisations') AND
			(
				o.id IN (SELECT DISTINCT organisation_id FROM ds_organisation_data) OR
				o.id IN (SELECT DISTINCT id FROM organisations WHERE type_id = 9)
			) AND
			o.type_id IN (9,1089)
			
	ORDER BY z.name, o.name


	-- Other organisational sets
	INSERT INTO search (scheme_entity_id, entity_id, entity_type, term, [table], [order])
	SELECT	'organisations-' + CAST(o.id AS nvarchar),
			o.id,
			'Company',
			o.name,
			'organisations',
			2
			
	FROM	organisations o
			
	WHERE	o.id NOT IN (SELECT DISTINCT entity_id FROM search WHERE [table] = 'organisations') AND
			o.type_id IN (283,993,1062,1217,1499)
			
	ORDER BY o.name
	
	
	-- Update organisations
	UPDATE	s
	SET		s.term = o.name + CASE o.type_id WHEN 283 THEN ' (MVNO)' WHEN 1217 THEN ' (MVNO)' ELSE '' END + CASE WHEN z.name IS NOT null THEN ', ' + z.name ELSE '' END
	FROM	search s INNER JOIN organisations o ON (s.entity_id = o.id AND s.[table] = 'organisations') LEFT JOIN organisation_zone_link oz ON o.id = oz.organisation_id LEFT JOIN zones z ON oz.zone_id = z.id


	-- Authors
	INSERT INTO search (scheme_entity_id, entity_id, entity_type, term, [table], [order])
	SELECT	'authors-' + CAST(a.id AS nvarchar), a.id, 'Author', a.name, 'authors', 100
	FROM	content_authors a
	WHERE	a.id NOT IN (SELECT DISTINCT entity_id FROM search WHERE [table] = 'authors')
	ORDER BY a.name

	-- Update authors
	UPDATE	s
	SET		s.term = a.name
	FROM	search s INNER JOIN content_authors a ON (s.entity_id = a.id AND s.[table] = 'authors')
	WHERE	s.is_alternate_term = 0 -- Exclude entities with multiple convenience names

	-- Delete orphaned authors
	DELETE	s
	FROM	search s LEFT JOIN content_authors a ON (s.entity_id = a.id AND s.[table] = 'authors')
	WHERE	s.[table] = 'authors' AND a.id IS null


	-- Tags
	INSERT INTO search (scheme_entity_id, entity_id, entity_type, term, [table], [order])
	SELECT	'tags-' + CAST(t.id AS nvarchar), t.id, 'Tag', t.name, 'tags', 10
	FROM	tags t
	WHERE	t.id NOT IN (SELECT DISTINCT entity_id FROM search WHERE [table] = 'tags')
	ORDER BY t.name
	
	-- Update tags
	UPDATE	s
	SET		s.term = t.name
	FROM	search s INNER JOIN tags t ON (s.entity_id = t.id AND s.[table] = 'tags')
	WHERE	s.is_alternate_term = 0 -- Exclude entities with multiple convenience names
	
	-- Delete orphaned tags
	DELETE	t
	FROM	tags t LEFT JOIN content_entry_tag_link et ON t.id = et.tag_id LEFT JOIN blog_entry_tag_link bt ON t.id = bt.tag_id LEFT JOIN document_tag_link dt ON t.id = dt.tag_id LEFT JOIN feed_tag_link ft ON t.id = ft.tag_id
	WHERE	et.tag_id IS null AND bt.tag_id IS null AND dt.tag_id IS null AND ft.tag_id IS null
	
	DELETE	s
	FROM	search s LEFT JOIN tags t ON (s.entity_id = t.id AND s.[table] = 'tags')
	WHERE	s.[table] = 'tags' AND t.id IS null


	-- Countries, UN and custom regions
	INSERT INTO search (scheme_entity_id, entity_id, entity_type, term, [table], [order])
	SELECT	'zones-' + CAST(z.id AS nvarchar),
			z.id,
			CASE z.type_id WHEN 10 THEN 'Country' ELSE 'Region' END,
			z.name,
			'zones',
			1
			
	FROM	zones z
			
	WHERE	z.id NOT IN (SELECT DISTINCT entity_id FROM search WHERE [table] = 'zones') AND
			(
				z.type_id = 10 OR
				z.id BETWEEN 3908 AND 3934 OR
				z.id IN (3824,3896,3899,3900,3902)
			)
			
	ORDER BY z.name
	
	-- Update zones
	UPDATE	s
	SET		s.term = z.name
	FROM	search s INNER JOIN zones z ON (s.entity_id = z.id AND s.[table] = 'zones')
	WHERE	s.is_alternate_term = 0 -- Exclude entities with multiple convenience names
	
	
	-- Flags
	UPDATE search SET has_content = 0, has_blogs = 0, has_documents = 0, has_feeds = 0

	-- Always mark regions as filterable
	UPDATE	s
	SET		s.has_data = 1, s.has_blogs = 1, s.has_documents = 1, s.has_feeds = 1 -- TODO: add has_content when find_by_fragments allows descendants
	FROM	search s
	WHERE	s.entity_type = 'Region' AND s.[table] = 'zones'

	-- Content
	UPDATE	s
	SET		s.has_content = 1
	FROM	search s INNER JOIN content_entry_author_link ea ON s.entity_id = ea.author_id
	WHERE	s.[table] = 'authors'
	
	UPDATE	s
	SET		s.has_content = 1
	FROM	search s INNER JOIN content_entry_entity_link ee ON (s.entity_id = ee.entity_id AND s.[table] = ee.[scheme])

	UPDATE	s
	SET		s.has_content = 1
	FROM	search s INNER JOIN content_entry_tag_link et ON s.entity_id = et.tag_id
	WHERE	s.[table] = 'tags'

	-- Blogs
	UPDATE	s
	SET		s.has_blogs = 1
	FROM	search s INNER JOIN blog_entry_tag_link bt ON s.entity_id = bt.tag_id
	WHERE	s.[table] = 'tags'
	
	-- Documents
	UPDATE	s
	SET		s.has_documents = 1
	FROM	search s INNER JOIN document_entity_link de ON (s.entity_id = de.entity_id AND s.[table] = de.[table])
	
	UPDATE	s
	SET		s.has_documents = 1
	FROM	search s INNER JOIN document_tag_link dt ON s.entity_id = dt.tag_id
	WHERE	s.[table] = 'tags'
	
	-- Feed
	UPDATE	s
	SET		s.has_feeds = 1
	FROM	search s INNER JOIN feed_entity_link fe ON (s.entity_id = fe.entity_id AND s.[table] = fe.[table])

	UPDATE	s
	SET		s.has_feeds = 1
	FROM	search s INNER JOIN feed_tag_link ft ON s.entity_id = ft.tag_id
	WHERE	s.[table] = 'tags'


	-- Update scheme_entity_id
	UPDATE search SET scheme_entity_id = [table] + '-' + CAST(entity_id AS nvarchar)
END
