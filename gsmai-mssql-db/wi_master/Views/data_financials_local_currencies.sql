CREATE VIEW dbo.data_financials_local_currencies
AS
SELECT     ds.id, m.id AS metric_id, m.name AS metric, a.id AS attribute_id, a.name AS attribute, o.id AS organisation_id, o.name AS organisation, z.id AS country_id, 
                      z.name AS country, ds.date_type, ds.date, CASE WHEN ds.val_i IS NULL THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22, 6)) END AS value, 
                      (CASE WHEN ds.val_i IS NULL THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22, 6)) END * cr.value) * (1 / cr2.value) AS value_local, c.id AS currency_id, 
                      c.iso_code AS currency_iso_code, c2.id AS local_currency_id, c2.iso_code AS local_currency_iso_code, ds.source_id, ds.confidence_id
FROM         dbo.ds_organisation_data AS ds INNER JOIN
                      dbo.metrics AS m ON ds.metric_id = m.id INNER JOIN
                      dbo.attributes AS a ON ds.attribute_id = a.id INNER JOIN
                      dbo.organisations AS o ON ds.organisation_id = o.id INNER JOIN
                      dbo.organisation_zone_link AS oz ON o.id = oz.organisation_id INNER JOIN
                      dbo.zones AS z ON oz.zone_id = z.id INNER JOIN
                      dbo.currency_rates AS cr ON ds.currency_id = cr.from_currency_id AND ds.date = cr.date AND ds.date_type = cr.date_type INNER JOIN
                      dbo.currency_rates AS cr2 ON cr.to_currency_id = cr2.to_currency_id AND ds.date = cr2.date AND ds.date_type = cr2.date_type INNER JOIN
                      dbo.zone_currency_link AS zc ON z.id = zc.zone_id AND zc.currency_id = cr2.from_currency_id INNER JOIN
                      dbo.currencies AS c ON ds.currency_id = c.id INNER JOIN
                      dbo.currencies AS c2 ON zc.currency_id = c2.id
WHERE     (m.id IN (10, 18)) AND (a.id IN (0, 826, 834)) AND (cr.to_currency_id = 2) AND (cr2.value <> 0)

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
         Begin Table = "ds"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 213
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 251
               Bottom = 114
               Right = 408
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "a"
            Begin Extent = 
               Top = 6
               Left = 446
               Bottom = 114
               Right = 601
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 6
               Left = 639
               Bottom = 114
               Right = 851
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "oz"
            Begin Extent = 
               Top = 114
               Left = 38
               Bottom = 192
               Right = 191
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "z"
            Begin Extent = 
               Top = 114
               Left = 229
               Bottom = 222
               Right = 395
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cr"
            Begin Extent = 
               Top = 114
               Left = 433
               Bottom = 222
               Right = 597
            End
            DisplayFlags = 280
            TopColumn = 0
         End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'data_financials_local_currencies';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'         Begin Table = "cr2"
            Begin Extent = 
               Top = 114
               Left = 635
               Bottom = 222
               Right = 799
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "zc"
            Begin Extent = 
               Top = 114
               Left = 837
               Bottom = 222
               Right = 992
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 192
               Left = 38
               Bottom = 300
               Right = 193
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c2"
            Begin Extent = 
               Top = 222
               Left = 231
               Bottom = 330
               Right = 386
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'data_financials_local_currencies';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'data_financials_local_currencies';

