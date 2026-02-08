-- ============================================================================
-- StrengthWise Migration: 27_v5_fix_equipment_column.sql
-- ============================================================================
-- 版本: v5.1
-- 日期: 2026-02-08
-- 生成方式: scripts/tools/generate_equipment_migration.py
-- ============================================================================
--
-- 修復 exercises.equipment 欄位
-- 原始值為 Firestore 舊格式，更新為 ref_equipment.id 標準格式
--
-- 更新: 779 筆 exercises
-- Equipment 類型: 19 種
-- ============================================================================

BEGIN;

-- ab_wheel: 2 筆
UPDATE exercises SET equipment = 'ab_wheel' WHERE id IN ('8KYr8g28so75VVoYClZU', 'sltf7Lo57jYe64xLzt7R');

-- barbell: 105 筆
UPDATE exercises SET equipment = 'barbell' WHERE id IN ('27169ouGiXmLotyu67ev', '2fzl0cO6gX5hriSpwqfY', '2zz6J3zz1iF2VKUcF1CF', '37HfmVRA1CLMcLN8JrNh', '3qRLPXd4NjEf5nWPtXme', '3qq7MX6T6VYUVmKr3SYv', '3zsvNeYy7QC4NNbfB8Cf', '4RbrRLTWa6mQlRwwZVMX', '4TOejkrh1GnBp9y8J0SP', '5feGZhN82iCVsi4G4o6u', '5zugpwilef43vX8V4AtX', '6WfuotgcYxOxfDvnaCmc', '6qACWH6jucZzo1FP1Q7f', '6tRNZcQKCRopVrM3SqDo', '7D3Y3G00nJiuAQwUGzxd', '7rP7m1jhYkdQEWYr2Obb', '83bXkxJJCgBsfLlFc62c', '8IYmlDjWFsCrbksIvIWR', '8nTCiqwuZUQ0loCz27G0', '9HXBdakMRf0cBBKL75IX', '9yjm4JuH7kzFpBoQOcOa', 'Ak25LLNvnuFotcP88mzL', 'AskdOoEg0vMmy9ZKH5k5', 'B4KCxchIfjkkdI8JezHM', 'BXUqzmZ52cglwL6JTjrX', 'CGnh2qLZPFLDm040iWNj', 'D2BC1UXsl3n3l3EVTJxk', 'DCKBzgmZho95iqWRUuc2', 'EB86apHwFkkdLvfItSg3', 'EvpCp81h2gnXr3geFRFF', 'FvgopoZfx6LOqNEAREKj', 'GXT3WtBpcFTClagX7xIy', 'HbGHiny76tAHpFJsp6LB', 'J5857VwzXstUuxH2jj5J', 'JVH9KnrvOaxpGDzhbL8J', 'K4mqZDi4YEfL8N2RlwC3', 'KMubdHnQ6Q9Bgc3T7I02', 'KweAmi2DEzLwlPAXddmG', 'L1VYeLb1bu2KHoyHaGb4', 'L8s6ZaQNBVj6lXo2Vwjt', 'LJJjAT7stZxT18KYjuVy', 'MzbeTLa2bBl7pkJdLAtU', 'NezSkLDmli15vQj2ZJzk', 'NtXEBlt70BR85DZ1NJ69', 'On4XIijXHAA4VOB5Yg1y', 'OsAAuVPonCFcWchbjJwx', 'OvRhcm6IgYZmxRvshGIF', 'Pj07JkKi1m30EZl7XNK2', 'Q3oP77mlxw1ZvLN8ZN1K', 'RQ8pk5yEFG6eoniKZrIj');
UPDATE exercises SET equipment = 'barbell' WHERE id IN ('SHHM022pBffBsfkRvoFd', 'V0EoF2mcGfAkuWeNyQ6H', 'VOiJBqL0aN0MytPrVW07', 'VjTIFp7BKeBBJ2NvGEU1', 'XrIupPxcyjmbs2rkFb5E', 'Y1kQ4U3z9eo98pPOg4rS', 'YcAwp1VkruGlFF1bbkTw', 'Zl8EuomuDc1W431QEGfJ', 'a918J6Zb9xLYejvNyQHn', 'aHXeyHbxnmk7aZGXI0k4', 'aTSIUw5zG0rLDPDZJGKn', 'aYYO0zPhg5kM53GqJs2l', 'aslLvOQIKHbMQ3MgffGE', 'b7DD3OBXJDwNf5r60POe', 'bLO5sNVTlB4T7Rl50ozE', 'bUJwBRXBNqxJplHMkHxy', 'eLP6AdVMWgTlKFaD27rZ', 'fgNrEARU5atxRb10WYv9', 'fpaDbLifwXM7vF1QvE8h', 'gONqOTu5z59ksF9w15fn', 'gOouhRK7OHpM5zG9eIme', 'guMubToVfWjFyqhS7y1t', 'hiAJp5dNLoZJbuyieRSs', 'ht3upVLCFOzkV2hZ9L0E', 'ipb07TgpgqGs8ceCkyCr', 'itEvg4ZVorwC5V9G28w4', 'jqEvAKqXwHzoaxYNPf78', 'kIvsBBtdGENy8aJYR9Z0', 'lL6ZdnE3qz1Qw0BSSRfX', 'm1xzTn6iJygnGbv0o8Mj', 'nHD18hIjlXF0dzjD0Mk4', 'nHs5mxijS6VizygFAe8k', 'nrC3wDp1rMMAJjRGUnfz', 'oAjJoL0oqf0fPZCGa1GH', 'pFi3iEcHrAPaQ3MO4iOd', 'pJRkM8gHJeKc60kpD214', 'q64S8060jckEbl0btWGH', 'q8CXsBbxuYxgQLvkGdoT', 'qPA0TyvRHLug3WSMHYUq', 'qRAySrI4HZDVPk4OVBUO', 'qmBTaxS4zCGrkNlQQKYt', 'qw4YKRbuXx0L3sMGIxEC', 'rUKfdmhpTjf2qPdfZ8F0', 's5eVzEoWsdNLfjfwJF1v', 'sUKXLKkYQQI4MwcPhEKy', 'shSMlJQF26HEZrXNqyHy', 'trbBsYqzlJhyq2jMamLO', 'uLeEc9k5GsfeuSc1CY32', 'upehr0pw7J2MGFM6TXpE', 'uvB0VVUw2HlBu5eWS3t0');
UPDATE exercises SET equipment = 'barbell' WHERE id IN ('vkbwpMPQZ6OWtAhSBMSy', 'wEsIhFXSfTWkByBcj1VB', 'x5norzDgNY5TsIMaJ3bb', 'ynUm5Y4Ed6Eueg41tVkt', 'zL7ZbmicIVAsWxsnXeRA');

-- battle_rope: 12 筆
UPDATE exercises SET equipment = 'battle_rope' WHERE id IN ('03g9loX3XxvLPMsI0Qax', '0KtgJcOwEVsyE8YeDug0', '7u0BM7s7ra7Jqt0LMbxy', 'BOaaPuJamqimR4oxiIDw', 'G6nhc5okCf7dbt7rL5bu', 'QMZalYkcgvtlYX6YQXvO', 'TC6nrwhemnkJmkNK6Lu9', 'UEgFMfIC86QKIwaDqzQW', 'dEaFsdl27usXbQsmBZet', 'iaeNNAv3OxmJVwSQOYY4', 'u1w8DyUEKppzOrUZsOaT', 'xgGudoTwCeDrvnYOKDi9');

-- bodyweight: 120 筆
UPDATE exercises SET equipment = 'bodyweight' WHERE id IN ('0TkbIQC0RO59KpkXFRqc', '1KnQeFzJfRYzWdgEDiRX', '1P9tu2NHGF5g8CaqDQ51', '2T48kjhyl8oJxJwsS6A7', '47Kroneg2x0LvG1NOYMW', '4Heh4sIQNoF3ey80W7yG', '4ZoRqHxz7WFgVaOv5t2c', '4fuF1GMRbUH3A7QphDEv', '4p3lzjIs8fEILtVJBqsz', '4y7zl3rnOi2uyulmHGVT', '5cvSIdEvxEswFArnGlWM', '66z6KA0uGDJLZ8xdjp4s', '6hS3PoFfbatsHCm0f1ii', '6mMd1EMonuwNpujwiqlr', '7UemmcAgteYtVPs7DevN', '7W5lhO6hF3RRWXXsAEue', '8BLxnffcg2bNMeBAnrJW', '8NOnagmAr0nKJu18tknC', '8w8s2OwgrDjuEOX9btfD', '9dD9QZSooQoQlYTzQ4bh', 'AyUGk5aJ2mRzFrTj0npj', 'CGeYbQl9cKN80lampNQH', 'CTW8vwkuwkK0acBqIUSY', 'D5AbMQpQnllNssoE3YIj', 'DdYJYCwSbdkP8oitIi6i', 'FWIz8IyekZJmH9cvGte0', 'Fiq5NDMIeqQrveUvc61T', 'FvkcgW53hiGB3wIEtdet', 'HIxJvtHCyoKtHQeyYRbL', 'HSAPk3YzT3PZrjXzE1uy', 'HeTju4BAbJVsrXNtlw0P', 'HoENO5xDWeCeaYqnFCGu', 'IBZUzCsawQHtu69lFbKZ', 'IL7eohuPjoyBACg7aoUm', 'IddEn24B8vLSVpm1jWbg', 'K9Q4WAM7wgCT7YaaK9Ss', 'KuqdlbhGApnUaUr3LTdM', 'L6h1rWAmj5Gnw39z84Dc', 'LM9ptsTHjSsGwwqxdoLD', 'LmyMzon8GsBm752AbY8R', 'LnbmMVbWMmHnxtdHS3me', 'MheifPWSVPyL6tkrDJeq', 'Myk1mJILLrYU93LihKLj', 'N8bUPRj0SwwFUEKRt5ip', 'NZ8MBO7Bjv9eydgNRfB8', 'NoXu3UmQvOekWzmjQheT', 'O4nPzcKzYLfucuDuwDml', 'O85IXDbVzi4B6QTCPMtH', 'O8es5rjXetamtdZQ61Xc', 'OWE6a2GGXF0h0CQFpES5');
UPDATE exercises SET equipment = 'bodyweight' WHERE id IN ('Q2jbMOUXQfwNmegeL1IZ', 'QKHjSgDjysDStol50Mxs', 'QMQf1gjVqKchXPTK4xiw', 'QqlaDaXLzXn6g92jvI6k', 'RmTeaBVOmFp2sX9FNzM4', 'STpYH9kgiGjuOfePc5KF', 'Sd4qbfTpSFxT2zy60iGf', 'TEPpYv5OzBVoH8gvPcsh', 'Tfgkw3xosrgC9jwVWuJb', 'U5hlYjuGdKRBFOccmHus', 'UrliDCHQpo2h9BghUaFJ', 'VO6RBR8POFdy3QwI2isv', 'VrcppDYPkUbY0JEblH0K', 'VvEuzqyPqmFaE9EkplsB', 'WMztpPrBtEcjzHDHW5sB', 'WmvnnY38ZlaXMbP0DxEN', 'XFuqTAYkSwUgWKlHCP7L', 'XN9QsyFNZ3uHDQTvAE3Z', 'YS07XTAyXmCrHViWPS6F', 'YnytTzU27T8Vh9nqnebq', 'YvoiJxA37vqymV53J9LL', 'Z5JcYfv7b91XYfLVkfjH', 'ZN85H6i8ycA0tnOg0Ltq', 'ZNZNlGUhAgxz9sOBTrKq', 'aQTakWhc4SYqlZY41c9I', 'axVVpj7RpMghquxgt25q', 'bpR31H1Nb0uzhtKeRFrI', 'btXldJ9MiE6AkH9dFQdj', 'bw3mU5Iu2QEXCq6ioHic', 'bzSqeuz2uHGBdH4diMyx', 'cGgNZx5z3gCr2lohhEIB', 'cn0RGITf11xUrs6OG60M', 'dFY4w6EI9SPSfWXqjPz7', 'dnbhgYx4cxiFa73bVn7A', 'eCHsq3BSBR70da7zLcxX', 'eQU0X91VvcF4s9MJKbXd', 'eZhpfwO3r4h8Bh0ekS5F', 'eeLwxu5ezkMBpyEJdSMB', 'efXGF3OAZZVeUqqALnbI', 'g0HIOpyHepcpVDhrGUfW', 'g5Wc4L1kfQDRFDcyj9bo', 'gm7mkOI7hF3P8ZJ7G9Dt', 'h1hC0VuRL6BBOaQuVXvb', 'hApGOa9vCl8uDniQowOL', 'hxtY1n8wJvxN3k4cMfqS', 'i76EufqlOOoVXzTSYkfo', 'jsdUQfPnPqr7hBtb5jWD', 'kz2TfiV24IKMFiMW5Y0C', 'llI45qF2kb9iMHFZ7fIK', 'md0PfFEskJdPPjAqh6Qf');
UPDATE exercises SET equipment = 'bodyweight' WHERE id IN ('mz5luuwzAOr8BEVFxWD8', 'n8nbbfBcVtgzjawCaDU2', 'nd5Mlhjo6Kghx3tUizLm', 'od3HN425htaXCayjF0D4', 'pdANnRYYxuFbFyahM0ux', 'ppOE2s7BH5i7C6KfpXKm', 'qFfm1F2GYZSNpYNDeDAe', 'sqMynNLEwiHntf8q51v6', 'tpiKg3MUbszWO1BmcKIh', 'u8Z6ecu3arogDSo6NHJ5', 'ubrV5Rkn5Dcre0yaX9CT', 'wNA66MwosQqEhCSsveZm', 'wxf0oqYTXfdJGLbulCNl', 'xHxRXbaDFyLbC3tDDu6j', 'xYCi5OTXnNUVFLk4ufZW', 'y14vRYRb2M6f8Dne9W9j', 'ycpImRdrGG0oZlV8rPvc', 'z8DV2GboGcoftnGv70wH', 'zYo7sr8m5s0hXLwKPJJV', 'zqiNpzWDuzcGW47iGoXy');

-- cable: 146 筆
UPDATE exercises SET equipment = 'cable' WHERE id IN ('0A5921M6WAyUv7fXcA29', '0RrJyyFHtD74r3yorad9', '0eQhPYz3G0dOJMTusLso', '0jefeXi8F69ggfXUc0rl', '0kG9MDoluBMw5s5JwHl6', '0kQP7mvrlE2LxyiwkjLF', '0mW6dygKvgDHBZW73t6C', '1AT4P8Ztzg119wIeXL9e', '1ShoMEdZQ4nHTzNoOYWK', '2Cnws8s2KvunJtImJieI', '2FxXOaXFSeC5zDV8G3Yn', '2b6q0gWw22JfXDU5tn2T', '328hfSzxgid81mi1t5ut', '3El2GhIETooZjLinFjro', '3t0GTW7hWv4DPk9wBWwX', '4ozhglKhP6bMvasASJBf', '5uTAcFXOskYvMGNMqcQ7', '6pFlYtEqcRzAxSOadmg5', '7JcUHSIYXm7G9h0inxp8', '7tjs9GxItsXliNvMd8x9', '8AHoQm0ruqhq9DquDEV8', '8MIOs5wIdwwjLGAG6Ey1', '8MosjPp8qHKKyG7kSEFw', '8PJKU1xduXWFLvz2O2aC', '8WkB8x58YqYWHYorHJvE', '8feynJNLychmFu436z10', '8js4vyf2hqUpYBXM4us4', 'ARL1RmTU570PT3HMGUGq', 'AZPLWVFgo5l7mWID7uKR', 'AlH96QH2quQm2zVk6xsl', 'BXoZyaTMXiHE867ksLKM', 'BXr2VKYH9YEApP8ujIFU', 'Bq2qA3r3yEAVqRyHJ6rs', 'C1rTsjxMrihCBymqacU9', 'DGhnFvT1ZzJdOVngDKaT', 'ENeYnvqdLOv5Sye0cHfQ', 'EZbXxi6T5cJiSpU9tPt7', 'G1i68CyM5RtOJT9xuH68', 'GLVcjtr6kx9wvvscnRTm', 'GQ38FNDtffSanuFfqByy', 'GavaLXDZovXnH7659JRx', 'GiQPvesUASXOkLuW5v2e', 'GmQKMjG96hIC3FqInzJq', 'HHGbMSe3WwCp6wQqavVl', 'HNY03QHAPhqA3K5AZwQF', 'Ik4kVH09iYjbA089rpQu', 'Jor1WT7j1pEEkRZoiTJ1', 'K18H8UwivqpK84NH0Tgz', 'KFor9P2Ru8mu3YqnsmS6', 'KJoXwlj6QKS1XEBaPPBX');
UPDATE exercises SET equipment = 'cable' WHERE id IN ('KPswKtqK3pWqFOr8Oloq', 'KYXYvOeOKyvyHNY9RubY', 'KZkXjjOr9wpxX3SDGahv', 'Ku9V0JhlXU8D7L34zVci', 'L5fHRShGfCTIm4IwDpT9', 'LVqcQSuGaTM7OUDsWM23', 'LXmpjH2P127eTYXHINSx', 'LfynmyUA3TZ9i4UMUrsi', 'M0952xnrR9kK0Kcok5zC', 'MiURamlJo2rOrUNF0zGo', 'MqOjIp725WHnN52mym10', 'N5kheXfjQcoVJkahCdYp', 'NGovDGOHAeiS9Lvlf5lQ', 'NZQh6Lv87sdULtkEvlOG', 'Ojwct2u0UErhaApE3Kbm', 'QA3xoEx8GRNiBguiUOA3', 'QhZrLD5QWU7l4CcKMph9', 'R5e8UBdcGgKLMR3Ne38d', 'RBRxLUlKhVmzRe8yE1Iz', 'RCo2Cw9IMmSpUyj6iInS', 'S80zfhAyL9gRZ3mdovax', 'SFl2VppYNzovIZwvwdaZ', 'Skc0d6OUaWHU2vKSbHvG', 'TRIIfZbQ8W0ritX8wXg2', 'TjTJVLMs6OttDcNhOMXH', 'VLmhtwf2zFRQWC4vXjJ5', 'VSTwIVKKMqrlYYBVgfYu', 'VdoIvCf4zAgv94OvC74A', 'WmEWOc1q2jqLjYGgPsD0', 'XIbRRNpiYhWn0NPI8ezg', 'XzMIVGx09ryDPgyTqqxk', 'Y8K22MFk1Vwhb43mcUzp', 'YJzV17eJTnaLYv6zco7j', 'YV6CsGdgEi2jr6lL3pIU', 'YmW2YLkRU2mWNCSlL3M9', 'Yx3XvKh67yJWbrgisSlG', 'YyBYvGPYhKFSSCzaGHEU', 'Z8B9ax0mBaDagRJydUwV', 'ZmwKmnqFT9iH5jUKl9Tt', 'ZuUKacLgdGySP04OLfgD', 'aGuHsnJzeU023xiq4Orp', 'anPj6kv4MqlIaTAMjhgP', 'aoFvCmcU1TykX74tfWEk', 'bQtAw7UYQktYWIB25Hcj', 'd5Q29cjfUpZjZu9lAESB', 'd8w3h50ks4eMOSBYrbhx', 'ddtpz9LidDuqgKkkdl8c', 'deruv50IWHnktGMcm2gV', 'dnfKy5nteDrAjVvpLOpv', 'e7KfdNfjL9vDQzXTGVV8');
UPDATE exercises SET equipment = 'cable' WHERE id IN ('epESULjvAdcbCIBCEvrj', 'fSBofQBgGxeNVAeHQoXP', 'fm0mMsgCFSxdA6cysLGF', 'hfgscTnitjVY14JeSajS', 'hwfIP57f06UVYZEbrx7u', 'i5yoKqBPZ6pwznXzamzs', 'iRUHitT2XZoHWNAkcmFp', 'iuSlsw3P5Rwz3qSpTpTA', 'kCdBCO930Q5WxCpeHmyq', 'kE6mJXS20nJr6Ye6Z3QC', 'lNWEY8kcHJbvE5houD93', 'lj7QJ2TFSZXbDoX5gHMZ', 'm3LGlWVtqFEaAaWsIidc', 'mQx21sW346flvjiZO0Qz', 'nAW61TJzhnc8Fk05RMHb', 'nXg3uVFqhSnnAgOasndq', 'oA9X1KFCDgaQcjJNmVAo', 'omhXp3wWAJksXJqvA46P', 'p1zL0PpvcBErU7z7U2tc', 'pjYIMemssXeZzCNL0gFq', 'qNSHCH4Htfa1aPRTRaaD', 'rSQfzLik9xKrxccGzKJz', 'sF34cv7bBx4MM0jzFfwj', 'sWTCpAn3zdyTqcVBhA0z', 'skMtp9xkJcc5HpR04G8n', 'spGdLjaUfdn2g18o2oNU', 'szYNZLBeuJFsEqBnkomB', 'tX1YEmxNXaeGfhL9VLQu', 'tyUiUiMyTCVlOgHtZuLb', 'u4mXi4Fjm932uOriuD59', 'ubYScmLXAlsF6pyKQ8rt', 'uzcAXsho2c4PIQIy40nQ', 'wG0wkI8RegKo2DggKrDc', 'wQnkvE3LJv4JAxVKw7tV', 'wY0wgDATn1ZMwANGKbZI', 'weXp6PpRCW6sq45Ok7b9', 'wzBwOOTxx1ammuc1sgfL', 'x3MSSmKrYiplgRoBQFrZ', 'xB8ieRtkCiQLeuydAy5Y', 'xoXsdlCJV8pVsoKaRRXb', 'yED5yUhQgKzvTSqJGITU', 'yQEvvbgLUNUpXFb03xH3', 'yUhnhWoM0ZFRqANCbX8c', 'yetWaLRv1ghluvIZHgwA', 'z7t7H4iRX3eN8xo225O0', 'zHu9Q73PF4FTPpXaIPOu');

-- cardio_machine: 7 筆
UPDATE exercises SET equipment = 'cardio_machine' WHERE id IN ('0mwjK0S7F6EV8PC9Ohj6', 'CrPGoUkHbnkfqn0gYC4a', 'Kao6qgQ9KoGXuZOxOK7X', 'T8ZdklS0Acfw0cffrLue', 'YGk22Ck9WigYaGrEpLoN', 'yRDbJbJfCcYMIVAcFxqC', 'yfZnBreHL5pf1jMyBAPa');

-- dumbbell: 152 筆
UPDATE exercises SET equipment = 'dumbbell' WHERE id IN ('0K1ohnKBkP3CBriDuwpx', '0UD3dhFWQUWGXRq1kWNF', '0cHIY1SKk1d4OYaQrA1t', '2DeZfox55TfdzMzO4TX2', '2aAGvDCKJL3Js6wDElEq', '3BgDNvmcM6OUebKWSZ1W', '3CEvFf9zLhHe18mZnSRu', '3G4OrRPEYkhizBokDziz', '3zSsgybTr13z75CRHBqq', '44AI6Os0BHcVcVT18QLI', '4Ts3lQq5AvuPz8OH3oeH', '5L73ALYAFZ7Ed87T9TR7', '5Zlxy0aLjE6SrbOvMy2M', '5yNv0j7fdFEEpuLpA1x5', '68LkjjJiPazCovWmZoII', '6HWfAoRtVdnSitA0a5Gk', '6JdtHMMAFOve5Vv73qrr', '6gHkiUWvSyQyPNPoqTnr', '7eV7GEf9it3HCc449uWz', '8wckUv1lsFYTw0fDUqPH', '9NyoUvX0UHjGUruqG6gT', '9ZVVVs4jGmxOn4SoAZTB', 'AMtv1eGFg9j9dWzzcgZM', 'APANHl6F6O2WCkQHjHGR', 'ARXgzsLQUlXmPL48qBK5', 'ASdAv9rU4iCfAHDpmC8j', 'AWReJj1y8TGxcqskOsD9', 'AWe8D9vKDmnb4EpJrtJQ', 'As0QwLPmLQ8PoUZfS17v', 'B2wGJVwsnAlyzSqrVuov', 'CUpvGdr1WLvZV4rYtHuH', 'ChWRQ9KqQHEVezJqEQgn', 'CzjexrXBXlPPz3EOzmya', 'D72QdvEtc4TXHHsRdANv', 'DTDl7jOGWzmwrUFHqVuZ', 'Du5uyPM1Pbp1ZwB2DtdG', 'E9GWaq8Kay6cZdlwjbJh', 'EmjMil4pfZosVPWYykZi', 'ErBUW2Uf24LHva5zy3vh', 'F66lLW4HANSUTgzpWcXS', 'FEU7UlBHj1eo4MrLs4Zy', 'FTWKLgL7cmvLTfswjhhI', 'Fbu2VbMR6wcVJX83pKfb', 'GZH3loO5UK04OKe0iwGn', 'GowdGdNKN7lVXeXt4gUv', 'IdpcQRUMoqJ7YGoBSbD8', 'IiJ9XIhBwMOcGF5QFUrN', 'JtwBfUfT5B0XXBnbZTIe', 'Jz2PqW0pt3A1iCgrI4Wn', 'LKaYRSShFpTVC4SgHXCD');
UPDATE exercises SET equipment = 'dumbbell' WHERE id IN ('LLBr6Mid1Qw3WxfTBLwM', 'Lb5GW8UY5Mv6OKkbFzU1', 'Lp8qhXr365AlugDJI2h4', 'M6KK7n4IVbEjndNTXPbo', 'MFmY9N8dMgMyMx53bNVk', 'MNZBp8633ZFQRXHbz3SI', 'N5Jq6m3OZBwg6giUz6n8', 'OR6T3GnNElFM8ts6repb', 'OwvlKV0HwdtWqtYIaFqx', 'PDaoA8A86K4ziXGeTMaW', 'PFFXaYWeCmWGNSgwq8AZ', 'PQzPNjn4YpTuC16Rtu9e', 'QBg9tXSqJefLjcJcf12t', 'QcuZdi172XWAayfrmY6M', 'QkMjUNXkK6wxzYHluXMR', 'Qy8qkFOLAk23hBtK3pXV', 'R60057ttmgvXs8cC3f2L', 'RqbSWJZ4WuPn8Izp7pKz', 'Ry4XmtUeRMF0qf3zTBFY', 'SasP4jMk2aeUyqvIUEuw', 'TZ1OC2DKAoJnHNPYqWcT', 'Ta2lMZNPP4OxjYFTgsqS', 'TulKuMUewI6zvTs7Uv7O', 'TzRTNUFTdTsxoT5a7Nxv', 'UBQv2RMFSe8OYCfbod7g', 'UkK3Cjm9XwEfJZXNWfJ1', 'VB2zh08YknD4Tsp4yFxb', 'VDcLd9TZQ0csz40CVJ9D', 'VMk5lCMeD4SkP0Y457Hp', 'W6ey18eoKzsqoO2xIKSC', 'Wcuaqrs07cLSavf9ULAI', 'XXeZglMvQey4QpniLyTo', 'XjfjEt8CAagFw20JBLcL', 'YU2EmZixTtVAKElhVjnv', 'Ydp5DkMhoHiYU3wskcg9', 'ZdXexRyD2ZTXgYBNZEu7', 'aVJR49tigRwEBPF49c8K', 'bhQhAwmELnvrelmb3wyE', 'boZiQvoMWBPtw4trE8va', 'c5pgPdXzHAoM5VMFDPum', 'c9FmQMkIBNk4nJMyS0vr', 'cyS9jPWWb7W5fEzYxIys', 'd6scq22hhgsh1rN0Ob6p', 'eFSKi7KFpyrjvWbekrh5', 'f53UjHt6W8455M7TnAuW', 'fC5kUkyqV3M5MowLkXSZ', 'fFybRp24gh4h4jKwKbGC', 'fnAGW141dwp1YxePS2SA', 'gGzUHnJnJtAmZ4C7h53S', 'guIKnd1XIWWgisKF1Ksn');
UPDATE exercises SET equipment = 'dumbbell' WHERE id IN ('hNVzQqrot4B5pMZJq5ej', 'hzdHjX3WDWNhL4CSy6cS', 'iqPCKFg72HMUYS3KiIeM', 'j0ctQzPb343syQL96Eyj', 'jLxYlmupQkeL8dUMeqQB', 'jlseUzIWj9qC7CXuQMaa', 'k1d17T35KqVLflavxTEI', 'kBwyh7Q9JvDwqYocu1ht', 'kDNC5asZFMwRAjpoZOWe', 'kS1ZlxTlAg0DBNA4L6sU', 'kYqNyTKZoislvAcgjUh7', 'kkvC7Qa1D2HPPW6a4WqA', 'kvk1vyp2qYvcMPfrzUT8', 'l0jULNZ9oYIihOakvVjE', 'lASgWpuSCfHmzGzU37KI', 'lhUk4YbDwdmzQVuQ3d5L', 'lmoqpKFNhM4cKlkQ96VS', 'lwHEXw1LaGg3WMzVrKeP', 'lzBQSijqhFC2RbJsofwQ', 'mUVixz5JekzoCYAydsu7', 'mc4wc7pc6oD2JoMNG2QN', 'myprUJVbdY7RVHbFG7Ob', 'nBxtiklZOLz1B1UFUB50', 'nIgpT7f9iiL581V0ANor', 'nXIpD7WLGsA57rVOBgya', 'nYqisyPfqJFj89Cct4Xr', 'oLXXnre3KtY2vZN6HEl8', 'oh3awYwPydmfum8kUhGK', 'oj42MBlyykehqhb7RjD8', 'pqWjvTUg97MLxHt0uG28', 'qW3nNKHuVjIkM0WBlJQM', 'rO0Noxs2y7M3cziIxKUD', 'sF0KJ4VJIqAT6YGw6gx6', 'snbsVXRmA6omrlzbzF5C', 'tKUhdnnoebLw8Ci11Gd9', 'tPPxqCljelmppHlVdsFm', 'tXBlrkdtKlmPKGYMnOwV', 'tltGTYItJPhOcXLW6xMU', 'txLeImLKMpXjkCADEGM8', 'uKx9Yja8yjIFvgV5FksJ', 'uQ1MDn8CWYoM6gJbsK3w', 'ufDOeMA4qvO537Iqiy3a', 'ussHyldzz2xjx5tSyKvN', 'vhvHLd6BFu561MuRogQg', 'vkq8cKBI6tmBC6GUm0U4', 'vrVnkwNPAaiWlUldmQN5', 'vyHzBaS5n1qqWteazIN6', 'xMeTrPnb9Za41BjYC2wj', 'xksIup78nOPAIwi1jJIr', 'xmEKues5b3X6DUtQVQXS');
UPDATE exercises SET equipment = 'dumbbell' WHERE id IN ('zqhxRlnrwXOzaPATcShU', 'zruaHar3JDctKknG6Rwd');

-- ez_bar: 1 筆
UPDATE exercises SET equipment = 'ez_bar' WHERE id IN ('xMFmvpKuSkXahEAJS4bp');

-- foam_roller: 9 筆
UPDATE exercises SET equipment = 'foam_roller' WHERE id IN ('7E0NiWEExkkj7HGYCNyx', 'QiKIAdJ1trGEYHsmJvXn', 'RVdSbGax8QQlYagyu23v', 'ae56ikNoQ0LdxD6EVz9Y', 'b7g9tPXJIMszVFDuBON1', 'bCJ9LqBuNEGalKZjAxxG', 'qfDpGK0YksOcjPbWOZow', 'qqYdQ40scYpuYvIhlCNB', 'uMfzQRdFiER7H04AnK5I');

-- kettlebell: 23 筆
UPDATE exercises SET equipment = 'kettlebell' WHERE id IN ('1mNnHDkHMtc8sDTWvzrD', '8zeM17AnT4CwFTaeJZbE', '9O3Mmo0nPoERAbjeaxiH', '9UvKQJosJThjkQbBaJtd', '9njNYawRscOAnDEhzL4d', '9tqGGRpapJ1lfEtH0dDw', '9vxMpwisFCHjNZfH1sEs', 'B5HCwYW9VR9bt8dNS5VS', 'I98XIJi61KTJ6qna5cEc', 'LzuVxN5MyxyeHMZJOVyK', 'ZsncSDO0xBKGCiK7CBSi', 'abeigFP23DUxoiWHDK1I', 'avOQC6uOIqNpWSWmBesu', 'cAXIgzYhtiRDFtQgGaWi', 'dNqA7mVFxTIcCSwyQqYz', 'eqdsWEsnTrBbVuhFQea8', 'hL5w3jFs5nsnb2iliZbN', 'kYkujkRGjNbUzenrFdvF', 'koxUUDyl5U7B5yfRxT0Y', 'mc6Yq8GL3bkjtDb4SodT', 'mnfARzs4EZxy0aHIvCdu', 'tM17WoPyXPb6fqwDiRH8', 'zCcpFJ2hUYvJdL1K2plR');

-- landmine: 32 筆
UPDATE exercises SET equipment = 'landmine' WHERE id IN ('2ogEKeUmfmsAl8H16d8o', '4Tu81TTR2h9fJbpOXYBm', '5CGTKT0xnkQiB4Ac83jy', 'Chqevzxo7F49lQzH2zvY', 'ClDNmgazH8Xgon1NQM2N', 'DxCCgpiLAbXfimZ2q5I0', 'FMm1YHLMWZXBxCoKaNuB', 'GDQGCl0mBpdnkHXpvhfu', 'GXbAZ7R06Yqc1TwCnVb2', 'I1Tq2FtybJwRKMaeuMbM', 'LBT1M0VlwPBKztsByAY0', 'Lcg5WESrF7CSZ5hr5cNA', 'MbVkK4l8I1uzXFWnRkrQ', 'SqHhFAPny6JGmxcyTSvv', 'TC0njt8QMxFEEDvkLi0f', 'WAxxze6gIKB5XYTf5JIx', 'XIFAhr2Q8dxZZO6WswlK', 'asT9COgbi2KWFWxpOmk2', 'bLdqB01ODsY4XhZsQkSm', 'feWGdUuRPpkay8EfD503', 'iUwdkM7V07p0K16Niy5e', 'jMitkTN3y3am0da0zqPK', 'jnTBDbdbESAWpSEF5Wc5', 'mwMIWJg7UxFoNEfmtPpD', 'oM0jxtYoXkSyVRLpkGgq', 'oSFxBpGa6CsuBPgOQjw3', 'oSNx8e6TTKA5hXbZEeIj', 'qtiVkCztZb3U0GsNeGQR', 'sDKwEsKtfTrbeYCMYrvS', 'vgMHs3qka3rsPOKtwJug', 'zrmwf4qh6Um4PiNKNkPG', 'zvDcdnziLLesfkuUDmfQ');

-- log_bar: 1 筆
UPDATE exercises SET equipment = 'log_bar' WHERE id IN ('LJg7cVmkBNiv3ccHy2Bb');

-- machine: 76 筆
UPDATE exercises SET equipment = 'machine' WHERE id IN ('0LDuIgLkNq4FHo9CCgLE', '10K2ezp4gturdUzW73iM', '3zRbsb2PYfA7eOLjgkls', '4HgrmJTz3KBWl6ZSurup', '57qnOY33boUNGcHkDIAC', '5BlZzjk6XL3rSdfkL14X', '6oN4FVCqZIuuM6SwYU2p', '7C0UKnrq8p3OI774NaNC', '8IwDLJ0rAMmNl2Q84fJZ', '8JXIZ8V3RKv72KXakxPD', '900DZKJkjgzr3wjIyplM', '9zJxlfvR5d0cGY6egSDZ', 'BpzRL7RUu16BKKJSlWFn', 'Bw1J06S0MdrOdSgaAd7d', 'Ck9BeSQDaTim6ZSLfiG7', 'DBHdHBWzBthZJpldciEq', 'Efh9uwKTrB4XysxJir6e', 'Ex5pKnUksmK2DSRwXeto', 'ExDyW7NyVRlaxxGruBJP', 'FCpuGBqCMOnnvPBiV9MT', 'FEn6pFW3n2jLz6q5ULNY', 'GQhCRrLL0lesDfqooaAR', 'Gd6DjhT0tLOqncS02ylH', 'JKw4HzFBJEHOE0hVxceD', 'JsfrN97Ep3rJKJkWTWEd', 'JxoByKqwElg7Du6gMQxS', 'LLu7ygZdCISW95DYeU2R', 'M77vk8wupcYralkUTup7', 'MB1RTPg3JxYqkNTJN7Dp', 'MgilgT5YtPn38Wzjr0DV', 'OiJI9GE4L33bAXF8BIp8', 'PiHEp2jQReyEs6oGsEMp', 'PrN0EbarLfPpBAoCn80S', 'Q5WIQGzitIb9JmScFAJW', 'RI1r3eyd2sjNHbqstc1d', 'RYYxAe4wb0AWAV3Hc6pz', 'TNmRDacLynB1OrEeBXNa', 'UXnSYdOK8kFPWGtV4Int', 'Uj2mUn6e321HBOwK5qbQ', 'VjRUx8474o6ywOIYRWmF', 'Vm2bfE6tK7aRVz3cDl07', 'W7YbnxdDLmFenHxp3Bdy', 'WMEgb6pc1NVFHxL94DzG', 'ZPlHQ7gc14DwOelLcudx', 'ZeYqcpKUF0QeoSr6wTNN', 'Zi0Mxbf90ReNPkQbwoj3', 'ZkUunF0KrMaGlxgCP3Du', 'cUNmpgrCyDpI5IMMitbO', 'dpc1e4txSyQR4JGbzgdV', 'f0hvXEdwQAzrw3SB8OTT');
UPDATE exercises SET equipment = 'machine' WHERE id IN ('foyP80d64D0hY3fYVup4', 'fvPophnqWfLUPA8tpqOb', 'gSjiHfdW3KxOiENz7hVl', 'gv7n7MEffMCf8e8dQa9F', 'hOQxvVFuNzDbXcgUNpDJ', 'k8Lp7R7IHf1KYdvC8kA0', 'kaAPDgfZyOO9woGwJQJ6', 'kai0uZw3aaWgC1hypVWG', 'mhapMB7c1cq6VBWTybfy', 'mxkBBRwIALPMYUeZExoC', 'ojMYV3CPMgkjcvKN7btf', 'pJ2t5Y8Q9AE7yk9HpCS3', 'r5d2DUtmJXBqG3MIC9lN', 'rGTPIiJX8sQ4e64EeZYh', 'rUrZHvkluTQKnfS0VHe3', 's3qLrzJJzhjIBaxNlbJP', 's9YaOWkyyLVSesHwDttf', 'tlKi5eCoKS0ss19qqlg0', 'uraonU4YW2gPzhcG3bYg', 'utIPTW9UU2LuYulZsZwQ', 'vZy56HZZErVQVyo8SAdZ', 'vdP08KNMejePEGkFPRqT', 'voqy4VIOhbkfrjcdlzqp', 'yENDF6uMxXzeBIDd9uYL', 'z7ZPqHjpE9XHVkEeAzKW', 'zGyxF11vlMzkclxXBwmr');

-- medicine_ball: 15 筆
UPDATE exercises SET equipment = 'medicine_ball' WHERE id IN ('1aDzNG0f3YcxcFZmZbC1', '4Qh8mm2QSFA9gax7BTVf', '4wrwnJRh7e6IoDug0Nll', '5V4fLte1UEfMAUyM0G2r', '6jp1nAJiOW7ODgw4YqVH', '98TVmq7c0TyaDnOAjHSe', 'DXoEBBpsMCBDL3CFNkPq', 'FiXXCVxKPw9r9RxyYsTT', 'Uhng2oq6NBcJ93eKD9d9', 'V3LVcMUcLLGxshLiilmM', 'Yb0u2nr05RihvUX02b5l', 'c4XJqsSfDedxOGiXKXHy', 'pIb7pNVQ4h55gz3SqCb4', 's9kuBD2Jseym3y5m1Tyi', 'sWh7lXPdvWONuxiKfQDN');

-- resistance_band: 23 筆
UPDATE exercises SET equipment = 'resistance_band' WHERE id IN ('5kBAfVimxNgWPJA7UHUa', '6hvpsp4UIyWptRYJYL2l', '75C0p5Sd5Vo0bonhm4SC', 'A669ubUcmQGvtE2ajwNv', 'Culf4Jwt5NfPGtIKTFXG', 'D7fXvGicyg8Caw1ND3W8', 'J1It0gGuwHXrMmFrIohQ', 'JKPHMx0qGHOoSAQYARLE', 'JSczZZwhb025Mzogoze2', 'Lv2FzVrMT0rY5Xxh0OJj', 'N80EYJQi2H3nq9SKf23o', 'S5TwcT9jDMV2PEnyecpq', 'TNdEqGhSruytPMiGU8KI', 'WKgcJz9LIb2sL1pNCgdF', 'Xij8A01t1wNgIK0wYclW', 'bdIINEJEDMuBtBd10um8', 'dCCTiw5XFJjogegGQYQT', 'rvpCii2MFG2Zsa7oJg0T', 'sv95ibMIZt5MsxDB1Wdz', 'tXyiEMti136kXTRjTlLw', 'xK2NhbamvHsOS6LiBnsB', 'zUbZxjJjQ1z0TdUB4EWy', 'zwvOGdLCIHRWAzDRrnlJ');

-- smith_machine: 23 筆
UPDATE exercises SET equipment = 'smith_machine' WHERE id IN ('46JsB2ODXD8CwYonC96z', '6g09pFdyv6i0CUyMqB7T', '78g8BiiTWSGJ8JbCZboY', 'FQG2TIR3bchZfjxcBxol', 'K8H4IButBSQraXb3AruK', 'MxhZZZcKOgcC13wuqiIz', 'SpnqrRvMSSortVaLi0Sq', 'YHABx7B1lYEmygfcqn8n', 'YPt6cDfRnlQLaCTMITvA', 'c4rDKEr9BVRKcmiJoK4X', 'dtNyiw7fLsGN2ZqQGyxN', 'eWpKPF473WV37lgJqimF', 'kKMoThPtpNnw8CXMTNEZ', 'lTLVCuYTYhr6uSUSIEVk', 'oXid9TyjgCZj58OFCfpz', 'qRaasvdSn7h7ruy2qfzY', 'qadcIHON7xhFgnMH0Ry3', 'vqiHbRWxU94wG4yM3W1I', 'xP2q5MK85jL5vFdJQ5cJ', 'xiUIkTZp3PeHJDTOqKro', 'yKAdsXanyFN2A8XTz2Nj', 'zIcaiVrcO51Z0thteESa', 'zY9vHejD6yL9XSFDfZO7');

-- specialty: 2 筆 -- ⚠️ 不在 ref_equipment 中
UPDATE exercises SET equipment = 'specialty' WHERE id IN ('Zi9WrYIXDkFYU9PNjED5', 'w9dMH2z3EjjRFZ1zC4RM');

-- suspension: 18 筆
UPDATE exercises SET equipment = 'suspension' WHERE id IN ('1RAneumuhcMTB8FVeT7c', '21vktm0UXFffyMfqjikF', '6GFVYF6xVVmHkNR1Jdvp', '7hRrHlaHwaVqajTHlbIZ', '84i8R6FXn88ABbEDv9cf', 'BnHn3WJF0e8PuQsMyzhr', 'Eh6KPbv5fzn1kVlnmIVl', 'GqS0fI0Snl9iusomYIMY', 'P1hVsRJRR8pJKcJeME1e', 'TSykZYb9gGH8GO7k1doA', 'ej6NbDujJQZmvzMqWTGp', 'fCegTcyuzBD2dCrNrBqo', 'fvWtjlB2SdwICpbuOaNk', 'gv0I0ISnMsCtlu0drl17', 'lXHZ8y7Y8xcQyAEVq0jA', 'mK98GHC6pmJuL22qmNmz', 'vwUkQ9S3Wjtw6vxp9kC9', 'yWPFNbCANAnu5otF2R5q');

-- vipr: 12 筆
UPDATE exercises SET equipment = 'vipr' WHERE id IN ('2gAX22jZONQ0XmUVKerm', '32Z5PF16MqxH82qo98tk', 'ASTyfpF2gnJE8bD8pA5r', 'EZfe9E3ipEPB8IwPugI7', 'GGBuTah0fr8yC1YOaiVG', 'NlItKfKeQ662aGz9WHQS', 'PNNl2CpoiqLeOCVxHAsL', 'SPumXgpDCXVxFU6uFLTh', 'UkcosE5lLKxGbEuLjOrK', 'ffLPwXBWji8Xcq9bpkoW', 'hY4p0saV3JpiCBSATQac', 't6n2EuzTWW6zIuXbEiTa');

-- specialty 器材：加入 ref_equipment 表
INSERT INTO ref_equipment (id, name_zh, name_en, description_zh, description_en, sort_order)
VALUES ('specialty', '特殊器材', 'Specialty Equipment', '特殊訓練器材', 'Specialized training equipment', 19)
ON CONFLICT (id) DO UPDATE SET
    name_zh = EXCLUDED.name_zh,
    name_en = EXCLUDED.name_en,
    description_zh = EXCLUDED.description_zh,
    description_en = EXCLUDED.description_en,
    sort_order = EXCLUDED.sort_order;

-- ============================================================================
-- 驗證
-- ============================================================================

DO $$
DECLARE
    matched_count INTEGER;
    total_system INTEGER;
    unmatched_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_system FROM exercises WHERE user_id IS NULL;
    SELECT COUNT(*) INTO matched_count FROM exercises WHERE user_id IS NULL AND equipment IN (SELECT id FROM ref_equipment);
    unmatched_count := total_system - matched_count;

    RAISE NOTICE '======================================';
    RAISE NOTICE 'Equipment 更新驗證';
    RAISE NOTICE '--------------------------------------';
    RAISE NOTICE '  系統動作總數: %', total_system;
    RAISE NOTICE '  Equipment 匹配: %', matched_count;
    RAISE NOTICE '  未匹配: %', unmatched_count;
    RAISE NOTICE '======================================';

    IF unmatched_count > 0 THEN
        RAISE WARNING '⚠️ 有 % 筆動作的 equipment 不在 ref_equipment 中', unmatched_count;
    ELSE
        RAISE NOTICE '✅ 所有系統動作的 equipment 都匹配 ref_equipment';
    END IF;
END $$;

COMMIT;
