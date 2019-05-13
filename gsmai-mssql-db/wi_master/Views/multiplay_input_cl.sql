CREATE VIEW dbo.multiplay_input_cl
AS
SELECT        m.id AS Metric_Id, m.name AS Metric, a.id AS Attribute_Id, a.name AS Attribute, 'Q' + DATENAME(QUARTER, o.date) + ' ' + DATENAME(yyyy, o.date) AS DATE, o.val AS VALUE, c.name AS Currency, 
                         s.name AS Source, co.name AS Confidence, omd.location_cleaned AS LOCATION, '' AS Page, omd.definition AS DEFINITION, omd.notes, o.created_on, zn.name
FROM            dbo.organisation_data_view_link AS ol LEFT OUTER JOIN
                         dbo.organisation_data AS o ON ol.fk_organisation_data_id = o.id LEFT OUTER JOIN
                         dbo.organisation_zone_link AS zl ON zl.organisation_id = o.fk_organisation_id LEFT OUTER JOIN
                         dbo.organisations AS os ON o.fk_organisation_id = os.id LEFT OUTER JOIN
                         dbo.zones AS zn ON zl.zone_id = zn.id LEFT OUTER JOIN
                         dbo.metrics AS m ON o.fk_metric_id = m.id LEFT OUTER JOIN
                         dbo.attributes AS a ON o.fk_attribute_id = a.id LEFT OUTER JOIN
                         dbo.sources AS s ON o.fk_source_id = s.id LEFT OUTER JOIN
                         dbo.currencies AS c ON c.id = o.fk_currency_id LEFT OUTER JOIN
                         dbo.confidence AS co ON co.id = o.fk_confidence_id LEFT OUTER JOIN
                         dbo.organisation_data_metadata AS omd ON omd.fk_organisation_data_id = o.id
WHERE        (o.fk_metric_id IN (350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 362, 363, 364, 366, 365, 378)) AND (o.date_type = 'Q') AND (ol.fk_data_view_id = 1) AND (o.archive = 0) AND (os.type_id = 1227)

GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ol"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 251
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 6
               Left = 289
               Bottom = 136
               Right = 475
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "zl"
            Begin Extent = 
               Top = 6
               Left = 513
               Bottom = 102
               Right = 683
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "os"
            Begin Extent = 
               Top = 6
               Left = 721
               Bottom = 136
               Right = 955
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "zn"
            Begin Extent = 
               Top = 6
               Left = 993
               Bottom = 136
               Right = 1178
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 1216
               Bottom = 136
               Right = 1421
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "a"
            Begin Extent = 
               Top = 102
               Left = 513
               Bottom = 232
               Right = 683
            End
            DisplayFlags = 280
            TopColumn = 0
         End', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'multiplay_input_cl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'
         Begin Table = "s"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 138
               Left = 246
               Bottom = 268
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "co"
            Begin Extent = 
               Top = 138
               Left = 721
               Bottom = 268
               Right = 891
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "omd"
            Begin Extent = 
               Top = 138
               Left = 929
               Bottom = 268
               Right = 1142
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'multiplay_input_cl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'multiplay_input_cl';

