# 動作分類系統 - 討論與分析紀錄

> 此文件包含動作分類系統設計過程中的討論、分析報告和研究資料。
> 正式規範請參考：`EXERCISE_CLASSIFICATION_ANALYSIS.md`

---

## 討論資料

我正在進行動作的重新命名
你看一下目前的分析報告與我的總結看一下看不看得懂

動作分類系統與資料庫架構重設計綜合研究報告：邁向多維度分類與直覺化搜尋執行摘要在當前的健身應用程式市場中，資料結構的僵化是導致使用者體驗（UX）摩擦的主要來源。傳統的單一繼承分類法（Single-Inheritance Taxonomy）迫使複雜的生物力學動作進入單一的「資料夾」，這不僅違背了運動生理學的現實，也限制了應用程式支援多種訓練哲學（如健美、健力、功能性訓練）的能力。本報告針對「動作分類系統重新設計」的需求，提出了一套詳盡的架構藍圖。本專案的核心目標是移除自動化處理的模糊性，轉而採用高精度的「人工重命名與標籤化」策略。透過建立一個基於關聯式資料庫（Relational Database）的多維度分類系統，我們將解構「動作」這一實體，將其從單一分類中解放，轉而透過「解剖學目標（Anatomy）」、「動作模式（Movement Patterns）」與「訓練分裂邏輯（Split Logic）」三個維度進行動態重組。本報告將詳細論證為何採用多對多（Many-to-Many）的資料表關聯設計是實現「多種分類檢視模式」的唯一途徑，並提供具體的命名協定（Naming Convention）與別名系統（Alias System），以徹底解決搜尋不直覺的痛點。1. 緒論：健身數據分類的認識論危機與重設計需求1.1 當前健身應用程式的分類困境現有的健身追蹤應用程式，如 Strong、Hevy 或 Jefit，雖然在市場上佔有一席之地，但在資料分類的底層邏輯上往往存在缺陷。這些應用程式通常採用「資料夾隱喻（Folder Metaphor）」，即一個動作只能隸屬於一個主要類別。例如，「硬舉（Deadlift）」通常被歸類為「背部」或「腿部」中的一種。然而，這種二元分類法無法反映硬舉作為一個全身性複合動作（Compound Movement）的本質 1。當使用者試圖以不同的訓練邏輯（例如「推/拉/腿」PPL 分裂訓練法）來檢索動作時，這種單一分類架構就會崩潰。如果硬舉被歸類在「背部」，那麼在「腿部日」的篩選器中它就會消失，這迫使使用者必須切換上下文，或手動建立冗餘的自定義動作。這種架構上的僵化，直接導致了使用者在搜尋時的挫折感，特別是當使用者使用通俗名稱（如 "Skullcrushers"）搜尋，而資料庫僅儲存學術名稱（如 "Lying Triceps Extensions"）時 4。1.2 重設計的核心目標與範疇本次重設計的核心任務是建立一個能夠支援「多視圖（Multi-View）」的底層架構。所謂多視圖，是指同一組動作資料庫，能夠根據使用者的當下需求，動態地重組為「解剖學視圖（依肌肉部位）」、「生物力學視圖（依動作模式）」或「訓練課表視圖（依 PPL 邏輯）」。由於本專案明確排除了自動化方案，轉而採用「逐筆人工重命名」，這賦予了我們對資料品質進行極致控制的機會。人工介入不僅是為了修正拼寫錯誤，更是為了賦予每個動作豐富的語意標籤（Semantic Tags）。本報告將涵蓋以下關鍵領域：資料庫正規化設計：從單一查找表（Lookup Table）轉向關聯表（Junction Table）的結構轉型。分類邏輯的深層解析：定義 NSCA 標準下的動作模式，並解決如「硬舉悖論」等邊緣案例。搜尋優化策略：透過別名表（Alias Table）實現直覺化搜尋，彌合專業術語與健身房俚語之間的鴻溝。人工重命名標準作業程序（SOP）：制定嚴格的「規格-器材-動作」命名協定。2. 理論架構：運動科學對資料模型的指引在深入資料庫設計之前，我們必須先確立指導分類的運動科學理論。資料庫的欄位設計不能僅憑工程師的直覺，而必須反映人體運動的生理現實。2.1 解剖學分類的侷限與必要性傳統的分類法主要基於解剖學，即「練哪裡（Where）」。這對於健美訓練（Bodybuilding）至關重要，因為其目標是肌肥大（Hypertrophy）與特定肌群的雕塑。然而，解剖學分類在功能性訓練中往往失效。例如，「盪壺（Kettlebell Swing）」雖然使用了腿後腱（Hamstrings）和臀大肌（Glutes），但其訓練目的往往是爆發力與髖關節鉸鏈機制，而非單純的肌肉收縮 6。因此，我們的資料模型必須保留解剖學分類，但將其降級為「屬性之一」，而非「唯一歸屬」。此外，解剖學分類必須區分「主動肌（Agonist）」與「協同肌（Synergist）」，以提供更精確的篩選結果。2.2 動作模式（Movement Patterns）：功能性觀點根據美國肌力與體能協會（NSCA）與功能性動作檢測（FMS）的標準，人體運動應依據生物力學特徵進行分類。這構成了我們資料庫的第二個主要視圖 6。主要的七大原始動作模式（Primal Movement Patterns）包括：蹲（Squat）：膝關節主導（Knee Dominant），軀幹相對直立。髖絞鍊（Hinge）：髖關節主導（Hip Dominant），膝關節彎曲極小，負荷集中於後側鏈（Posterior Chain）。弓步/單腿（Lunge/Unilateral）：不對稱支撐，涉及平衡與單邊發力。推（Push）：分為水平推（Horizontal）與垂直推（Vertical）。拉（Pull）：分為水平拉（Horizontal）與垂直拉（Vertical）。旋轉/抗旋轉（Rotate/Anti-Rotate）：核心的扭轉或抵抗扭轉能力。負重行走（Carry）：移動中的核心穩定與握力。將動作歸類為「髖絞鍊」而非單純的「背部訓練」，解決了硬舉分類的歧義性。這允許使用者在背部受傷需要避免脊椎垂直受力時，能透過篩選「動作模式」來尋找替代動作，這是單純解剖學分類無法做到的 9。2.3 訓練分裂邏輯（PPL）：使用者習慣的視圖「推/拉/腿（Push/Pull/Legs）」是中高階訓練者最常用的課表編排邏輯。這並非嚴格的科學分類，而是一種排程啟發法（Scheduling Heuristic） 11。推（Push）：涉及將重量推離身體中心的動作，通常關聯胸、肩（前/中束）、三頭肌。拉（Pull）：涉及將重量拉向身體中心的動作，通常關聯背、二頭肌、肩（後束）。腿（Legs）：涉及下肢的所有動作。在資料庫設計中，這必須被視為一種「標籤（Tag）」，而非「類別（Category）」。因為某些動作（如硬舉）可能同時屬於「拉」與「腿」，這需要資料庫支援一對多的標籤關聯 1。3. 資料庫架構詳解：支援多維度檢視的實體關聯模型為了達成上述的理論要求，我們必須捨棄扁平化的資料表設計，轉而採用高度正規化（Normalized）的關聯式架構。以下是建議的資料庫綱要（Schema），適用於 PostgreSQL 或 SQLite 等 SQL 資料庫。3.1 核心實體表（Core Entity Tables）這些表格儲存了系統中不可分割的原子資料（Atomic Data），是分類系統的基石。3.1.1 動作主表 (exercises_master)這是動作的唯一真理來源（Source of Truth）。為了支援人工重命名，此表中的名稱必須是經過標準化的「規範名稱（Canonical Name）」。欄位名稱資料型態描述與約束exercise_idINT (PK)唯一識別碼，自動遞增。canonical_nameVARCHAR標準化後的名稱（如 "Barbell Back Squat"）。必須設為 UNIQUE 以防重複。difficulty_levelENUM難度分級：'Beginner', 'Intermediate', 'Advanced'。mechanics_typeENUM力學類型：'Compound'（複合）, 'Isolation'（孤立）。用於快速篩選 14。is_unilateralBOOLEAN標記是否為單邊動作（如單手划船），這對計算訓練總量（Volume）至關重要。instructionsTEXT動作執行說明。3.1.2 動作模式參照表 (ref_movement_patterns)此表定義了生物力學的分類樹。透過 parent_id 實現遞迴階層（Recursive Hierarchy），允許 UI 展示粗粒度（如「推」）或細粒度（如「垂直推」）的分類 16。欄位名稱資料型態描述pattern_idINT (PK)唯一識別碼。nameVARCHAR模式名稱（如 "Vertical Push", "Hip Hinge"）。parent_idINT (FK)指向自身的 FK。例如 "Vertical Push" 的 parent 是 "Push"。definitionTEXT用於教育使用者的定義說明。3.1.3 肌肉部位參照表 (ref_muscle_groups)此表支援解剖學視圖。類似於動作模式，這裡也需要層級結構（區域 -> 肌群）。欄位名稱資料型態描述muscle_idINT (PK)唯一識別碼。common_nameVARCHAR通俗名稱（如 "Lats", "Quads"）。scientific_nameVARCHAR學術名稱（如 "Latissimus Dorsi", "Quadriceps Femoris"）。regionENUM身體區域：'Chest', 'Back', 'Legs', 'Arms', 'Shoulders', 'Core'。3.1.4 器材參照表 (ref_equipment)器材是另一個重要的篩選維度，特別是在居家訓練（Home Gym）場景中 18。欄位名稱資料型態描述equip_idINT (PK)唯一識別碼。nameVARCHAR器材名稱（如 "Dumbbell", "Cable", "Smith Machine"）。3.2 關聯表（Junction Tables）：多維度分類的引擎這是本次重設計中最關鍵的部分。我們不將分類資訊直接寫在 exercises_master 中，而是透過中介表來建立「多對多（Many-to-Many）」關係。這種設計允許一個動作同時擁有多個標籤，從而實現多視圖切換。3.2.1 動作-肌肉關聯表 (rel_exercise_muscles)此表解決了「主動肌」與「協同肌」的區分問題 5。欄位名稱資料型態描述exercise_idINT (FK)關聯至動作主表。muscle_idINT (FK)關聯至肌肉參照表。activation_roleENUM角色：'Primary'（主要）, 'Secondary'（次要/協同）, 'Stabilizer'（穩定）。應用場景：當使用者搜尋「練胸」時，系統查詢 activation_role = 'Primary' 的動作，顯示「臥推」。當使用者搜尋「三頭肌」時，系統可以包含「臥推」，但標示為「次要肌群」，或透過排序演算法將其排在「三頭肌下壓」之後。3.2.2 動作-模式關聯表 (rel_exercise_patterns)此表解決了複合動作（如 Thrusters）跨越多個模式的問題。欄位名稱資料型態描述exercise_idINT (FK)關聯至動作主表。pattern_idINT (FK)關聯至動作模式表。應用場景：對於「火箭推（Thruster）」，我們在此表插入兩筆記錄：一筆關聯至「蹲（Squat）」，一筆關聯至「垂直推（Vertical Push）」。這確保了無論使用者篩選哪種模式，該動作都會出現。3.2.3 動作-PPL 標籤表 (rel_exercise_split_tags)此表專門服務於訓練課表視圖，解決 PPL 分類的模糊性 1。欄位名稱資料型態描述exercise_idINT (FK)關聯至動作主表。split_tagENUM標籤：'Push', 'Pull', 'Legs', 'Upper', 'Lower', 'Cardio', 'Core'。應用場景：針對「硬舉（Deadlift）」，人工重命名者會在此表插入 Pull 和 Legs 兩個標籤。這完美解決了「硬舉該放哪天」的爭議，將決定權交給使用者當下的篩選條件。4. 搜尋優化策略：別名系統與人工命名協定除了分類邏輯外，使用者的另一個主要痛點是「搜尋不直覺」。這通常是因為資料庫中的名稱過於學術化，與使用者口語中的名稱（健身房俚語、縮寫）不匹配。既然我們排除了自動化，人工重命名階段必須同時建立一個強大的別名系統（Alias System）。4.1 搜尋同義詞資料表 (search_aliases)這是一個專門用於搜尋索引的表格，它將使用者的各種輸入映射到唯一的 exercise_id 21。欄位名稱資料型態描述範例資料alias_idINT (PK)唯一識別碼。exercise_idINT (FK)關聯至動作主表。關聯至 "Lying EZ-Bar Triceps Extension"termVARCHAR搜尋關鍵字（需建立索引 Index）。"Skullcrusher", "French Press", "Nose Breaker"localeVARCHAR語言/地區代碼（支援多語系擴展）。"en-US", "zh-TW"categoryENUM類型：'Slang'（俚語）, 'Abbreviation'（縮寫）, 'Clinical'（臨床）。'Slang'運作機制：當使用者在搜尋框輸入 "Skull" 時，系統不直接查詢 exercises_master，而是先查詢 search_aliases。系統發現 "Skullcrusher" 對應到的 exercise_id 是仰臥三頭肌伸展，遂返回該標準動作。這創造了一種「系統很聰明」的使用者體驗，實際上是依賴了人工建立的高品質同義詞庫。4.2 人工重命名協定：SEE 法則為了確保 exercises_master 中的 canonical_name 具有高度的一致性與可讀性，我們必須制定一套命名標準。根據研究，最佳的命名結構為 "規格 - 器材 - 動作" (Specification - Equipment - Exercise, SEE) 22。4.2.1 命名結構定義規格 (Specification)：描述動作的變體，如角度、握距、姿勢。若為標準姿勢可省略。詞彙庫：Incline（上斜）, Decline（下斜）, Seated（坐姿）, Standing（站姿）, Single-Arm（單臂）, Wide-Grip（寬握）, Reverse-Grip（反握）。器材 (Equipment)：描述使用的主要負重工具。詞彙庫：Barbell（槓鈴）, Dumbbell（啞鈴）, Kettlebell（壺鈴）, Cable（纜繩）, Machine（器械）, Bodyweight（徒手）, Smith Machine（史密斯機器）。動作 (Exercise)：動作的核心名詞。詞彙庫：Bench Press（臥推）, Squat（深蹲）, Deadlift（硬舉）, Row（划船）, Curl（彎舉）, Extension（伸展）, Press（推舉）, Fly（飛鳥）。4.2.2 命名實例對照表下表展示了如何將現有的混亂名稱轉換為 SEE 標準名稱，並將舊名稱轉入別名表。原有名稱 (Old Name)標準化名稱 (Canonical Name)命名邏輯分析別名表 (Aliases to Add)DB BenchFlat Dumbbell Bench Press補全角度(Flat)與全名(Dumbbell)。DB Bench, Dumbbell Press, 胸推SkullcrushersLying EZ-Bar Triceps Extension移除俚語，描述動作本質。Skullcrushers, French Press, 法式推舉Lat PulldownsCable Lat Pulldown (Wide Grip)指定器材(Cable)與握距(Wide)。Lat Pulldowns, 滑輪下拉, 背部下拉SquatBarbell Back Squat區分背蹲與前蹲，明確器材。Squat, Deep Squat, 深蹲RDLBarbell Romanian Deadlift展開縮寫，明確器材。RDL, Stiff Leg Deadlift, 羅馬尼亞硬舉TRX RowSuspension Strap Inverted Row移除品牌名(TRX)，使用通用器材名。TRX Row, Ring Row, 懸吊划船5. 分類邏輯深度解析與邊緣案例處理在人工重命名與標籤化的過程中，最困難的挑戰在於處理那些模糊不清的邊緣案例。以下定義了具體的決策樹（Decision Tree），供資料維護人員參考。5.1 硬舉悖論（The Deadlift Paradox）硬舉究竟是練背還是練腿？這取決於訓練者的目標與變體。解剖學標籤：Primary = Hamstrings, Glutes; Secondary = Erector Spinae, Traps; Stabilizer = Lats, Forearms。動作模式標籤：Hinge（髖絞鍊）。這將其與 Squat（膝主導）區分開來，對於膝蓋受傷的使用者來說，這是一個關鍵的篩選條件 25。PPL 標籤：標記為 Pull AND Legs。理由：在 PPL 課表中，有些人將硬舉放在拉日（因為背部參與度高），有些人放在腿日（因為是後側鏈主導）。資料庫不應強迫使用者選邊站，而應支援兩種情境 1。5.2 複合推舉動作（The Thruster / Olympic Lifts）如「火箭推（Thruster）」或「挺舉（Clean and Jerk）」。動作模式標籤：同時標記 Squat 與 Vertical Push（或 Explosive/Power）。PPL 標籤：同時標記 Push 與 Legs。應用：這確保了當使用者想找「全身性爆發力動作」或單純想找「腿部動作」時，該項目都能被檢索到。5.3 核心穩定性區分傳統分類常將所有腹部動作歸為 "Abs"。新系統需區分功能 27。動作模式：Flexion（屈曲）：如 Crunches。Rotation（旋轉）：如 Russian Twist。Anti-Rotation（抗旋轉）：如 Pallof Press。Anti-Extension（抗伸展）：如 Plank, Ab Wheel Rollout。價值：這對於復健與運動表現訓練至關重要。想提升短跑表現的使用者需要 Anti-Rotation，而非 Flexion。6. 實作策略：人工重命名工作流程由於本案排除自動化方案，我們需要一個高效的人工介入流程來處理數百甚至數千筆動作資料。6.1 階段一：資料審計與叢集（Audit & Clustering）在開始重命名之前，先匯出所有現有動作，並依據字串相似度進行分群。目標：識別重複項目。例如 "Dumbbell Press" 與 "DB Chest Press" 很可能是同一個動作。操作：將這些重複項目合併（Merge）為單一 exercise_id，避免後續維護困難。6.2 階段二：屬性賦值（Attribute Assignment）資料維護人員需針對每一個 exercise_id 執行以下檢核表（Checklist）：建立規範名稱：依據 SEE 協定重寫名稱。填寫別名表：將舊名稱、縮寫、俚語填入 search_aliases。標籤化 - 肌肉：指定 Primary 與 Secondary 肌群。標籤化 - 模式：指定其生物力學模式（如 Hinge）。標籤化 - 器材：指定所需器材。標籤化 - PPL：指定其在分裂訓練中的歸屬（可複選）。6.3 階段三：搜尋測試與驗證建立一組測試案例（Test Cases）來驗證別名系統的有效性。搜尋 "Booty" -> 應出現 Glute Bridge, Hip Thrust (透過別名關聯)。搜尋 "Guns" -> 應出現 Bicep Curls (若策略允許此類俚語)。搜尋 "Legs" + 篩選 "No Equipment" -> 應出現 Air Squat, Lunges。7. 使用者體驗（UX）的具體改善資料庫的重構將直接轉化為前端介面的具體功能升級 29。7.1 動態篩選器（Smart Faceted Filter）搜尋介面不再只有一個下拉選單，而是提供一組「晶片（Chips）」或「切換開關（Toggles）」：視圖切換：[ 依部位 ][ 依動作模式 ][ 依器材 ]情境篩選：[ ] 僅顯示複合動作 (Compound Only)[ ] 居家訓練/無器材 (Home Gym)[ ] 推系列 (Push Day)7.2 搜尋結果的智慧排序利用 rel_exercise_muscles 表中的 activation_role 欄位進行加權排序。情境：使用者搜尋 "Triceps"（三頭肌）。結果排序：Tricep Pushdowns (Role: Primary) - 排在最前。Close-Grip Bench Press (Role: Primary/Secondary) - 排在中間。Bench Press (Role: Secondary) - 排在最後。說明：這樣的排序邏輯比單純的文字匹配更符合使用者的訓練意圖。8. 結論本次動作分類系統的重新設計，不僅僅是一次資料清理，更是一次對健身數據結構的根本性典範轉移（Paradigm Shift）。我們從「單一繼承的資料夾結構」轉向了「多維度關聯的標籤結構」。透過引入 ref_movement_patterns 與 rel_exercise_split_tags 等關聯表，我們成功地讓系統同時支援解剖學、生物力學與 PPL 訓練邏輯，達成了「多種分類檢視模式」的需求。而透過 search_aliases 別名表與 SEE 命名協定的結合，我們在保留資料庫正規性的同時，極大化了搜尋的直覺性與容錯率。雖然人工重命名與標籤化需要大量的前期投入，但這將建立起一個高保真（High-Fidelity）、高靈活度且具備未來擴充性的資料基底，為應用程式的長期競爭力奠定堅實基礎。這套架構將不再強迫使用者適應系統的分類邏輯，而是讓系統動態地適應使用者的訓練思維。附錄：資料表設計總覽 (Markdown Tables)表 A: 核心實體關聯圖 (ERD) 摘要表格名稱類型主鍵 (PK)關鍵外鍵 (FK)用途exercises_masterEntityexercise_idN/A儲存規範名稱與基礎屬性。ref_movement_patternsLookuppattern_idparent_id定義動作模式階層（如 Squat, Hinge）。ref_muscle_groupsLookupmuscle_idregion定義肌肉與身體區域。ref_equipmentLookupequip_idN/A定義器材清單。rel_exercise_musclesJunctionN/Aexercise_id, muscle_id多對多關聯：動作與肌肉（含 Primary/Secondary 角色）。rel_exercise_patternsJunctionN/Aexercise_id, pattern_id多對多關聯：動作與模式。rel_exercise_split_tagsJunctionN/Aexercise_id多對多關聯：動作與 PPL 標籤。search_aliasesEntityalias_idexercise_id儲存搜尋用的同義詞、俚語、縮寫。表 B: PPL 標籤化邏輯範例動作名稱PPL 標籤 (Tag)邏輯說明Barbell Bench PressPush, Upper標準的上肢推動作。Barbell Back SquatLegs, Push下肢推動作，主要歸類於 Legs，但力學上屬於 Push。Barbell DeadliftLegs, Pull涉及後側鏈（Pull）與下肢（Legs），兩者皆可篩選到。Face PullPull, Upper上肢拉動作，強化肩袖與上背。Standing Overhead PressPush, Upper垂直推動作。表 C: 搜尋別名對照範例規範名稱 (Canonical)別名 1 (Alias)別名 2 (Alias)別名 3 (Alias)Lying EZ-Bar Triceps ExtensionSkullcrushersFrench Press仰臥三頭肌伸展Rear-Foot Elevated Split SquatBulgarian Split SquatBSS保加利亞分腿蹲Suspension Strap Inverted RowTRX RowRing Row懸吊划船Barbell Conventional DeadliftDeadliftDL硬舉

動作分類系統重建計劃 v2

設計原則：從「單一繼承分類」轉向「多維度關聯標籤」

核心架構：多對多關聯表設計

has

has

has

has

referenced by

referenced by

used by

exercises_master

rel_exercise_muscles

rel_exercise_patterns

rel_exercise_split_tags

search_aliases

ref_muscle_groups

ref_movement_patterns

ref_equipment

設計優勢

一個動作可屬於多個分類（如：硬舉 = 拉 + 腿）

支援三種檢視模式：解剖學視圖、動作模式視圖、PPL 訓練視圖

別名系統：解決「俚語 → 標準名稱」的搜尋問題

資料表設計

1. 動作主表 exercises_master

欄位型態說明idPK唯一識別碼canonical_nameVARCHAR標準中文名（SEE 格式）canonical_name_enVARCHAR標準英文名（SEE 格式）difficulty_levelENUMbeginner / intermediate / advancedmechanics_typeENUMcompound / isolationis_unilateralBOOLEAN是否單邊動作equipment_idFK主要器材tracking_modeENUMweight_reps / time / distance...

2. 參照表（Lookup Tables）

ref_movement_patterns - 動作模式

ID代碼英文中文父級1pushPush推null2horizontal_pushHorizontal Push水平推13vertical_pushVertical Push垂直推14pullPull拉null...............

ref_muscle_groups - 肌肉群

ID代碼英文中文區域1chestChest胸肌upper_body2pec_majorPectoralis Major胸大肌upper_body...............

ref_equipment - 器材

ID代碼英文中文1barbellBarbell槓鈴2dumbbellDumbbell啞鈴3cableCable纜繩............

3. 關聯表（Junction Tables）

rel_exercise_muscles - 動作↔肌肉

exercise_idmuscle_idrole12primary15secondary18stabilizer

role: primary（主動肌）/ secondary（協同肌）/ stabilizer（穩定肌）

rel_exercise_patterns - 動作↔模式

exercise_idpattern_id1215

一個動作可對應多個模式（如 Thruster = Squat + Vertical Push）

rel_exercise_split_tags - 動作↔PPL 標籤

exercise_idsplit_tag1push1upper

split_tag: push / pull / legs / upper / lower / core / cardio

4. 搜尋別名表 search_aliases

exercise_idtermlocaletype1Skullcrusherenslang1French Pressenslang1法式推舉zh-TWslang1仰臥三頭伸展zh-TWclinical

命名協定：SEE 法則

格式：[規格] [器材] [動作]



原始名稱標準中文名標準英文名DB Bench平板啞鈴臥推Flat Dumbbell Bench PressSkullcrushers仰臥 EZ 槓三頭伸展Lying EZ-Bar Triceps ExtensionRDL槓鈴羅馬尼亞硬舉Barbell Romanian DeadliftLat Pulldowns纜繩寬握下拉Cable Wide-Grip Lat Pulldown

工作步驟

Phase 1: 資料庫準備 🗄️

 1.1 設計並建立參照表（ref_* tables）

 1.2 定義動作模式階層（含父子關係）

 1.3 定義肌肉群清單（含區域分類）

 1.4 定義器材清單

 1.5 建立關聯表結構

 1.6 建立別名表結構

Phase 2: 資料審計與叢集 🔍

 2.1 匯出現有 749 個動作為 CSV

 2.2 識別重複項目（字串相似度分析）

 2.3 合併重複動作，建立唯一 ID 對照

 2.4 產出審核用 CSV 模板

Phase 3: 人工重命名與標籤化 ✏️

每個動作需填寫：

 3.1 規範名稱（中/英，SEE 格式）

 3.2 別名清單（俚語、縮寫、舊名稱）

 3.3 主動肌 / 協同肌 / 穩定肌

 3.4 動作模式（可複選）

 3.5 PPL 標籤（可複選）

 3.6 器材

 3.7 難度等級

 3.8 複合/孤立

Phase 4: 資料匯入與驗證 ✅

 4.1 匯入審核後的 CSV

 4.2 建立搜尋測試案例

 4.3 驗證多視圖篩選功能

 4.4 驗證別名搜尋功能

Phase 5: 前端整合 📱

 5.1 更新篩選器 UI（支援多視圖切換）

 5.2 實作智慧搜尋（別名匹配）

 5.3 實作搜尋結果加權排序（主動肌優先）

審核 CSV 模板欄位

id,原名稱,標準中文名,標準英文名,別名,主動肌,協同肌,動作模式,PPL標籤,器材,難度,複合/孤立,單邊

邊緣案例處理規則

硬舉 (Deadlift)

維度標籤主動肌腿後肌、臀大肌協同肌豎脊肌、斜方肌動作模式hinge（髖鉸鏈）PPL 標籤pull, legs

火箭推 (Thruster)

維度標籤動作模式squat, vertical_pushPPL 標籤push, legs

下一步

IMPORTANT

請確認此架構設計是否符合您的需求，確認後我將：

建立完整的參照表資料（動作模式、肌肉群、器材）

產出審核用 CSV 檔案（含 749 個動作）


動作分類系統 v2 架構評估與全量上線策略深度研究報告1. 執行摘要隨著數位健身產業的成熟，數據架構的擴展性與精確性已成為平台核心競爭力。本報告旨在針對「動作分類系統 v2」方案進行全方位的技術與策略評估。v2 方案的核心在於引入標準化的命名分類法（Taxonomy）與標準化資料庫架構，以解決舊有 v1 系統中數據冗餘、命名不一致及分析維度受限等技術債。分析顯示，v2 方案在學理與技術架構上具有高度合理性，特別是採用「規格-器材-動作」（Specification-Equipment-Exercise, SEE）的命名邏輯以及整合功能性動作模式（Functional Movement Patterns），這將顯著提升數據分析的顆粒度與用戶體驗。然而，從 v1 遷移至 v2 的過程存在極高的數據風險。特別是涉及多對一（N-to-1）的實體合併（Entity Merging）、用戶歷史數據的完整性保存，以及離線優先（Offline-First）移動端架構的同步衝突問題。基於風險評估，本報告強烈反對採用「大爆炸式」（Big Bang）的全量切換策略，因其在數據一致性與服務可用性上具有不可控的災難風險。反之，報告建議採用「絞殺者模式」（Strangler Fig Pattern）進行漸進式遷移，並配合雙寫機制（Dual-Write）、軟刪除（Soft Delete）策略及客戶端 UUID 遷移協議，以確保在系統升級過程中達成零數據丟失與用戶無感過渡。2. 系統 v2 方案的合理性評估：分類學與數據建模健身應用程式的價值日益取決於其提供深度分析的能力，例如訓練量負荷管理、肌肉平衡分析與個人化推薦。然而，傳統 v1 架構通常基於早期的簡單需求構建，導致數據結構扁平且缺乏語義關聯。v2 方案的提出，本質上是一次從「記錄工具」向「智能分析引擎」的轉型。2.1 動作命名法的標準化：SEE 協議的應用在 v1 系統中，最顯著的痛點是動作命名的隨意性與碎片化。研究指出，缺乏受控詞彙（Controlled Vocabulary）會導致同一動作出現多種變體，例如 "Bench Press"、"Barbell Bench Press" 與 "Flat Bench" 被視為三個獨立實體，這使得計算用戶的總推力體積變得不可能 1。v2 方案引入的命名標準化，特別是參考學術界建議的 「規格-器材-動作」（Specification-Equipment-Exercise, SEE） 或其變體 「動作 (器材) - 規格」，提供了必要的結構化語義。2.1.1 命名結構的邏輯優勢根據 Jackson 等人的研究，標準化的命名結構能消除專業人員與系統間的溝通障礙 1。組成元素 (Component)定義 (Definition)範例 (Example)v2 架構意涵動作 (Exercise)核心生物力學模式或傳統名稱。深蹲 (Squat)、推舉 (Press)、划船 (Row)作為搜尋索引的主要關鍵字 (Token)，支援模糊搜尋。器材 (Equipment)施加阻力的工具。槓鈴 (Barbell)、啞鈴 (Dumbbell)、壺鈴 (Kettlebell)允許用戶根據健身房設備進行過濾篩選 3。規格 (Specification)握距、站距、角度等修飾語。上斜 (Incline)、寬握 (Wide Grip)、單腿 (Single Leg)區分動作變體，實現精確的訓練負荷追蹤。這種結構化命名解決了搜尋體驗中的「從一般到特定」（General to Specific）問題 4。在 v2 中，當用戶輸入 "深蹲" 時，系統不再是返回散亂的字串匹配，而是能夠基於父子階層關係，聚合展示 "背部深蹲"、"前蹲"、"高腳杯深蹲" 等變體。這對於移動端有限的螢幕空間而言，能顯著提升資訊檢索效率，並支援按名稱或器材進行邏輯排序（A-Z 排序）5。2.2 功能性動作模式與肌群分類的演進傳統 v1 系統多採用「身體部位」（Body Part Split）作為唯一分類依據（如胸、背、腿）。這種分類法源於健美訓練邏輯，但在現代功能性訓練與運動表現訓練中顯得捉襟見肘 7。v2 方案建議整合 功能性動作模式（Functional Movement Patterns），這在運動科學上具有高度合理性。根據 Dr. John Rusin 與 Dan John 的理論，人體運動應基於六大基礎模式進行分類 9：蹲 (Squat)：膝主導的下肢推動作（如高腳杯深蹲、前蹲）。髖絞鍊 (Hinge)：髖主導的下肢動作（如硬舉、壺鈴擺盪）9。跨步 (Lunge)：單腿支撐動作（如分腿蹲、保加利亞分腿蹲）11。推 (Push)：上肢推動作，細分為垂直推（肩推）與水平推（臥推）7。拉 (Pull)：上肢拉動作，細分為垂直拉（引體向上）與水平拉（划船）7。負重行走 (Carry)：負重位移（如農夫走路）9。架構影響與多型關聯（Polymorphic Associations）：v2 的數據庫設計必須支援多對多（Many-to-Many）的標籤系統，而非單一分類。例如，「火箭推」（Thruster）這項動作同時結合了「前蹲」與「過頭推」，在 v1 的單一分類中，它被迫歸類為「腿部」或「肩部」，導致訓練量計算失真。在 v2 中，它可以同時繼承 Pattern:Squat 與 Pattern:Push，以及 Muscle:Quads 與 Muscle:Deltoids 15。這種多維度的元數據（Metadata）標記是實現進階分析（如推拉平衡分析、關節壓力監測）的基礎 17。2.3 資料庫正規化的必要性為了支撐上述分類邏輯，v2 方案要求將資料庫從非正規化狀態遷移至第三正規化形式（3NF）。實體解耦： 將 WorkoutLogs 表中的動作名稱字串（String）替換為指向 Exercises 表的外鍵（Foreign Key, FK）。標籤化架構： 建立 Tags 表與 ExerciseTags 關聯表，以處理複雜的屬性（如「複合動作」、「單關節動作」、「康復訓練」）18。這種正規化設計雖然增加了查詢時的 JOIN 操作成本，但對於數據一致性至關重要。當需要修正某個動作的拼寫或屬性時，僅需更新 Exercises 表的一行記錄，而非遍歷數億行的日誌表 21。3. 全量上線策略風險評估：大爆炸 vs. 漸進式遷移從 v1 到 v2 的遷移不僅是 schema 的變更，更涉及到底層數據的物理重組與邏輯清洗。特別是「合併重複實體」（N-to-1 Merge）的操作，具有不可逆的破壞性風險。3.1 「大爆炸」（Big Bang）遷移策略的極高風險所謂「大爆炸」遷移，是指在一段停機維護時間內，一次性將所有舊數據轉換為新格式並切換系統 23。對於擁有大量活躍用戶的消費級應用而言，此策略被評估為 極高風險。3.1.1 核心風險點分析停機時間與業務損失： 數據遷移與索引重建耗時極長。對於全球化運營的應用，長達數小時甚至數天的維護視窗將直接導致用戶流失 25。回滾（Rollback）的複雜性： 在大爆炸遷移中，一旦新系統上線並開始寫入新數據，若發現 v2 的分類邏輯有誤（例如錯誤地將某種特殊的復健動作合併到了常規動作中），回滾操作將變得極其困難。恢復舊備份意味著丟失上線期間產生的所有新數據 27。「幽靈數據」與同步衝突： 這是移動端應用特有的風險。當伺服器進行大爆炸遷移時，成千上萬的客戶端正處於離線狀態（如在地下室健身房）。這些客戶端仍持有 v1 的動作 ID。當服務恢復，這些客戶端嘗試同步舊 ID 的數據時，會因伺服器端 ID 已變更或刪除而導致嚴重的同步衝突（Sync Conflicts），甚至導致用戶剛完成的訓練記錄丟失 29。3.2 推薦策略：漸進式「絞殺者」遷移（Phased Migration）本報告強烈建議採用 漸進式遷移（亦稱並行運行或絞殺者模式），將風險分散到較長的時間軸上 24。3.2.1 實施階段規劃雙寫機制（Dual-Write / Shadow Writes）：在應用程式後端層建立適配器，將所有新寫入的訓練記錄同時寫入 v1 表結構與 v2 表結構。這確保了 v2 系統擁有實時數據，可用於驗證新架構的正確性，而不會影響現有用戶的讀取體驗 31。背景回填（Background Backfill）：啟動非同步任務，按用戶分批將歷史數據從 v1 轉換並遷移至 v2。這一過程可以包含複雜的去重邏輯（Deduplication），並且在遇到無法自動判斷的合併衝突時，將其標記為「待人工審核」，而非直接覆蓋 32。金絲雀發布（Canary Release）：先將 1% 的用戶切換到 v2 的讀取路徑（Read Path）。監控其查詢性能、數據準確性及用戶反饋。若發現動作分類有誤，僅影響極少數用戶且易於修復 34。逐步棄用：當 v2 系統穩定運行且數據完全同步後，停止對 v1 的寫入，並最終移除 v1 相關代碼與數據表 23。4. 數據合併（N-to-1）與用戶歷史保存策略v2 方案的核心挑戰在於如何處理 v1 時期遺留的「髒數據」。舊系統中可能存在成千上萬個由用戶創建的「自定義動作」，實質上是同一個動作（例如："Benching", "Bench Prss", "Chest Press (Barbell)"）。將這些 N 條記錄合併為 1 條標準化記錄（Golden Record），是實現數據分析的前提，但也最容易引發用戶不滿。4.1 合併邏輯與 SQL 模式在執行 N-to-1 合併時，必須更新所有關聯表（如 WorkoutLogs）的外鍵，將其從「重複 ID」重指向到「主 ID」36。SQL 處理模式參考：SQL-- 假設 ID 100 是標準化的 "Barbell Bench Press"
-- ID 50, 51, 52 是需要合併的重複項
UPDATE WorkoutLogs
SET ExerciseID = 100
WHERE ExerciseID IN (50, 51, 52);
然而，單純的 SQL 更新是不夠的。如果用戶在同一天記錄了 "Bench Press" (ID 50) 和 "Barbell Bench Press" (ID 100)，直接合併會導致同一訓練課中出現兩條針對同一動作的記錄，這在數據邏輯上是異常的。遷移腳本必須包含聚合邏輯（Aggregation Logic），例如將兩條記錄的組數（Sets）合併，或保留其中數據較完整的一條 38。4.2 軟刪除（Soft Delete）作為安全網在處理用戶歷史數據時，軟刪除是絕對的底線要求。嚴禁對被合併的舊動作執行硬刪除（Hard Delete）40。硬刪除風險： 一旦物理刪除記錄，若後續發現合併邏輯有誤（例如將「上斜臥推」錯誤合併為「平板臥推」），數據將無法恢復，導致用戶歷史訓練量永久性錯誤 42。軟刪除實作： 在 Exercises 表中增加 is_deleted 或 merged_to_id 欄位。被合併的舊動作在前端搜尋中隱藏，但在資料庫中保留。若用戶投訴數據錯誤，管理員可透過回滾 merged_to_id 欄位瞬間恢復數據原貌 43。最佳實踐： 對於用戶自定義的動作，系統不應強制自動合併。應採用「建議合併」機制，提示用戶：「我們發現您的 'Db bench' 與標準動作 'Dumbbell Bench Press' 相符，是否合併以獲得進階分析？」將決定權交還給用戶，可大幅降低客訴風險 45。5. 離線優先架構下的同步風險與 UUID 遷移移動端健身應用的核心特性是「離線優先」（Offline-First）。用戶在健身房地下室記錄數據，隨後同步至雲端。v2 遷移過程中，ID 變更對此機制構成了重大挑戰。5.1 ID 衝突與 UUID 的引入舊系統若使用自增整數（Auto-Increment Integer）作為主鍵（ID 1, 2, 3...），在離線環境下會產生嚴重問題。客戶端離線創建新動作時生成的臨時 ID，極易與伺服器端或其他客戶端生成的 ID 衝突 46。建議策略： 藉此 v2 遷移之機，將主鍵系統全面遷移至 UUID (Universally Unique Identifier)。優勢： UUID 可以在客戶端離線生成且保證全球唯一，徹底解決離線創建數據後的 ID 碰撞問題 46。遷移路徑： 在 v2 表結構中，主鍵應定義為 UUID 類型。對於舊有的 Integer ID，可以透過雜湊演算法轉換為 UUID，或在過渡期維護一張 Legacy_Integer_ID 到 New_UUID 的映射表 30。5.2 墓碑機制（Tombstones）與同步協議當伺服器端執行了 N-to-1 合併並軟刪除了舊 ID 後，離線客戶端的本地資料庫（如 SQLite/Realm）仍保留著舊 ID。當客戶端上線同步時，必須有一套機制告知客戶端這些變更。同步協議設計：墓碑封包（Tombstone Packet）： 伺服器在同步響應中，不僅傳回新數據，還需傳回「已刪除/已合併」的 ID 列表（即墓碑）。重定向指令： 對於合併操作，同步協議應包含 MergeInstruction: { old_id: A, new_id: B }。客戶端邏輯更新： 移動端 App 必須在後端遷移之前發布新版本，內建處理這些重定向指令的邏輯：在本地資料庫中將所有指向 old_id 的日誌更新為 new_id，然後刪除本地的 old_id 記錄 30。若不預先更新客戶端邏輯，舊版 App 接收到伺服器的合併數據時可能會崩潰，或因無法識別新 ID 而導致數據重複寫入（Sync Loops）49。6. 結論與執行建議「動作分類系統 v2」在學理架構與商業價值上均具有高度合理性。採用 SEE 命名法與功能性動作分類，將為平台解鎖高價值的分析功能，並改善用戶體驗。然而，全量上線策略若採用大爆炸模式，將面臨數據完整性崩潰的風險。關鍵行動建議：架構層面： 全面採用正規化資料庫設計，引入多對多標籤系統以支援複雜的動作屬性（如同時屬於「推」與「腿」）。標識符層面： 廢除自增 ID，全面轉向 UUID，以支援健壯的離線同步機制。遷移策略： 嚴格執行「漸進式雙寫遷移」。在確認 v2 數據與 v1 數據在雙寫模式下完全一致之前，絕不切換讀取路徑。數據安全： 對於合併操作，強制實施「軟刪除」與「審計日誌（Audit Log）」，確保任何自動化的合併錯誤皆可被逆向操作。客戶端協同： 在後端遷移啟動前，強制用戶更新 App 至支援新同步協議（含墓碑處理與 ID 重映射邏輯）的版本。透過上述策略，平台可在確保 100% 數據安全的前提下，完成從傳統記錄工具向智能健身數據平台的演進。表 1：v1 與 v2 系統架構對比特性v1 舊系統v2 新系統 (建議方案)優勢與影響命名規則自由文本 / 非結構化SEE 標準 (規格-器材-動作)提升搜尋精確度，支援多語系擴展 1。分類邏輯單一部位 (Body Part)多標籤 / 功能性模式 (Functional Pattern)支援交叉訓練分析，符合現代運動科學 11。資料庫範式反正規化 (Denormalized)第三正規化 (3NF)減少數據冗餘，提升維護性，雖然查詢稍慢但更準確 22。ID 類型自增整數 (Integer)UUID徹底解決離線同步時的 ID 衝突問題 46。重複處理允許共存規範化單一實體 (Golden Record)實現全平台的大數據分析與排行榜功能。表 2：刪除策略對比分析策略機制優點缺點適用場景硬刪除 (Hard Delete)SQL DELETE，物理移除數據。釋放儲存空間，簡化查詢。數據永久丟失，無法回滾，破壞關聯完整性 42。僅適用於暫存數據或法律強制要求刪除的個資。軟刪除 (Soft Delete)SQL UPDATE SET is_deleted=1。保留歷史，支援「復原」操作，維持外鍵完整性 43。資料庫膨脹，查詢需增加 WHERE is_deleted=0 過濾條件。v2 遷移的核心標準，特別是用戶歷史數據。

動作分類系統 v2 實作計劃
情境：目前無大量用戶，可直接重構不需複雜遷移策略
核心設計原則
原則v1 現況v2 目標命名規則自由文本/不一致SEE 標準（規格-器材-動作）分類邏輯單一部位多標籤 + 功能性模式ID 類型字串 IDUUID（離線同步友善）刪除策略-軟刪除（保留歷史）
資料庫 Schema（簡化版）
核心表
-- 動作主表
exercises (
  id UUID PRIMARY KEY,
  canonical_name VARCHAR,      -- 標準中文名 (SEE 格式)
  canonical_name_en VARCHAR,   -- 標準英文名 (SEE 格式)
  equipment_id UUID FK,        -- 主要器材
  mechanics_type ENUM,         -- compound/isolation
  is_unilateral BOOLEAN,
  difficulty_level ENUM,       -- beginner/intermediate/advanced
  tracking_mode ENUM,
  is_deleted BOOLEAN DEFAULT FALSE,  -- 軟刪除
  merged_to_id UUID NULL       -- 合併重定向
)

-- 搜尋別名表
search_aliases (
  id UUID PRIMARY KEY,
  exercise_id UUID FK,
  term VARCHAR,                -- 別名/俚語/縮寫
  locale VARCHAR               -- zh-TW, en-US
)
關聯表（多對多標籤）
-- 動作↔肌肉（含角色）
rel_exercise_muscles (
  exercise_id UUID FK,
  muscle_id UUID FK,
  role ENUM  -- primary/secondary/stabilizer
)

-- 動作↔動作模式（可複選）
rel_exercise_patterns (
  exercise_id UUID FK,
  pattern_id UUID FK
)

-- 動作↔PPL 標籤（可複選）
rel_exercise_split_tags (
  exercise_id UUID FK,
  split_tag ENUM  -- push/pull/legs/upper/lower/core/cardio
)
參照表（Lookup）
-- 動作模式（階層式）
ref_movement_patterns (
  id UUID PRIMARY KEY,
  code VARCHAR,           -- horizontal_push, squat, hinge...
  name_en VARCHAR,
  name_zh VARCHAR,
  parent_id UUID NULL FK  -- 父級模式
)

-- 肌肉群
ref_muscle_groups (
  id UUID PRIMARY KEY,
  code VARCHAR,
  name_en VARCHAR,
  name_zh VARCHAR,
  region ENUM             -- upper_body/lower_body/core
)

-- 器材
ref_equipment (
  id UUID PRIMARY KEY,
  code VARCHAR,
  name_en VARCHAR,
  name_zh VARCHAR
)
工作步驟
Phase 1: 準備參照資料 📋
 1.1 建立動作模式清單（18 種 + 階層）
 1.2 建立肌肉群清單（區域→肌群）
 1.3 建立器材清單（8 類）
 1.4 定義 PPL 標籤列舉值
Phase 2: 產出審核 CSV 🗂️
 2.1 匯出現有 749 個動作
 2.2 預填建議分類（自動推斷）
 2.3 產出審核模板
Phase 3: 人工審核與標籤化 ✏️
每個動作填寫：

欄位說明標準中文名SEE 格式（如：上斜啞鈴臥推）標準英文名SEE 格式（如：Incline Dumbbell Bench Press）別名俚語/縮寫/舊名稱（逗號分隔）主動肌Primary muscles協同肌Secondary muscles動作模式可複選（如：horizontal_push）PPL 標籤可複選（如：push, upper）器材單選難度beginner/intermediate/advanced複合/孤立compound/isolation單邊true/false
Phase 4: 資料匯入 ⬆️
 4.1 建立 UUID 映射（舊 ID → 新 UUID）
 4.2 匯入審核後資料至新表
 4.3 更新 App 端資料結構
Phase 5: App 整合 📱
 5.1 更新搜尋邏輯（支援別名匹配）
 5.2 更新篩選器 UI（多視圖切換）
 5.3 驗證歷史訓練記錄顯示正確
SEE 命名範例
原名稱標準中文名標準英文名推／伏地挺身／半跪式跪姿伏地挺身Kneeling Push Up舉重動作/上博/Power Clean爆發上博Power Clean戰繩/上下甩繩戰繩交替波浪Battle Rope Alternating Waves壺鈴／負重起身土耳其起身Turkish Get UpDB Bench平板啞鈴臥推Flat Dumbbell Bench Press
邊緣案例處理
動作動作模式PPL 標籤說明硬舉hingepull, legs同時屬於拉和腿火箭推squat, vertical_pushpush, legs複合動作雙標籤伏地挺身horizontal_pushpush, upper胸部為主引體向上vertical_pullpull, upper背部為主


動作分類系統 v2：實作計劃確認與資料生成深度技術報告1. 執行摘要與系統架構戰略概觀在數位健身與運動科技領域，從以解剖學為基礎的分類系統（Action Classification System v1）過渡到以功能性生物力學為核心的架構（v2），代表了運動處方生成邏輯的根本性典範轉移。傳統 v1 系統依賴於肌肉部位的簡單標籤（如「二頭肌」、「胸肌」），這雖然滿足了初級的搜尋需求，但卻無法支撐現代化、智慧化的訓練課表生成 1。v2 系統的核心目標是建立一個基於「動作模式（Movement Patterns）」的分類學體系，這不僅符合現代功能性訓練（Functional Training）的科學標準 3，更能為演算法提供關於人體力學、受傷風險控制及動作進階/退階的深層語意。本報告旨在為動作分類系統 v2 的實作提供一份詳盡無遺的技術藍圖，涵蓋了從理論分類學、資料庫架構設計、資料清洗與生成策略，到支援離線優先（Offline-First）的行動端同步協議。我們將深入探討如何將成千上萬筆非結構化的 API 原始資料，轉化為具有高度關聯性的結構化知識圖譜，並確保這些數據能夠在網路不穩定的環境下，透過強健的同步機制無縫地服務終端用戶。1.1 從解剖學視角轉向功能性視角的必要性傳統系統（Legacy Systems）的數據結構通常是扁平的。例如，在標準的 Fitness API 回應中，「深蹲（Squat）」與「腿屈伸（Leg Extension）」可能僅僅被標記為目標肌群是「股四頭肌（Quadriceps）」1。然而，從訓練生理學的角度來看，這兩個動作的價值截然不同：深蹲是一個多關節、閉鎖動力鏈（Closed Kinetic Chain）的動作，涉及核心穩定與神經肌肉控制；而腿屈伸則是單關節、開放動力鏈（Open Kinetic Chain）的孤立動作。若系統無法區分這種層級差異，自動化課表生成引擎就有可能產生邏輯謬誤，例如在一天內安排過多性質重複的動作，或忽略了推拉平衡（Push-Pull Balance）3。v2 系統採用的「模式優先於部位（Patterns Over Parts）」策略，將動作歸類為六大基礎模式：蹲（Squat）、髖絞鍊（Hinge）、弓步（Lunge）、推（Push）、拉（Pull）、負重/核心（Carry/Core）3。這種分類法使演算法能夠執行更高級的邏輯判斷，例如：「該用戶今日已執行過高強度的膝主導（Knee Dominant）動作，建議輔助動作應轉向髖主導（Hip Dominant）以平衡下肢壓力」7。1.2 系統範疇與核心交付物本實作計劃確認書涵蓋三大關鍵技術領域，每一個領域都將在後續章節中進行顯微鏡式的檢視：功能性分類學與本體論（Taxonomy & Ontology）： 定義「動作」的靜態資料結構。這不僅僅是資料欄位的定義，而是建立一套描述人類運動的標準語言，包含難度分級、力學機制及禁忌症。資料生成與遷移工程（Data Generation & Migration）： 設計一套自動化的 ETL（擷取、轉換、載入）流程，利用自然語言處理（NLP）與規則引擎，將現有的 API 原始資料 1 映射到新的 v2 分類架構中，並生成用於壓力測試的合成數據。離線優先的基礎設施（Offline-First Infrastructure）： 針對移動設備不穩定的網路環境，設計基於 SQLite 的本地資料庫架構，並實作「最後寫入勝出（Last-Write-Wins）」的衝突解決策略與增量同步（Delta Sync）協議 10。2. 理論框架：功能性動作分類學詳解動作分類系統 v2 的基石在於對人類動作模式的精確定義。這套分類學並非憑空創造，而是嚴格參照了當前運動科學界的主流共識，特別是功能性動作篩檢（FMS）與肌力與體能訓練（CSCS）的標準 4。資料生成的準確性完全取決於我們如何將這些生物力學特徵轉化為程式可識別的規則。2.1 六大基礎動作模式（The "Big Six"）系統必須能夠將任一動作實體（Entity）歸類到唯一的「主模式（Primary Pattern）」中，同時允許「次要屬性（Secondary Attributes）」的存在。2.1.1 蹲舉模式（The Squat Pattern - Knee Dominant）蹲舉模式的生物力學特徵在於髖關節、膝關節與踝關節的同時屈曲（Simultaneous Flexion），並伴隨著重心的垂直下降。雖然髖關節在動作中扮演重要角色，但相較於髖絞鍊，蹲舉更強調膝關節的屈曲角度與股四頭肌的發力 7。生物力學機制：主動肌： 股四頭肌（Quadriceps）、臀大肌（Gluteus Maximus）。穩定肌： 豎脊肌（Erector Spinae）、腹橫肌（Transverse Abdominis）。關鍵特徵： 軀幹相對直立，脛骨前傾角度較大 3。v2 分類子型（Sub-types）：雙邊對稱（Bilateral Symmetrical）： 如背槓深蹲（Back Squat）、高腳杯深蹲（Goblet Squat）。這是發展下肢絕對力量的基礎。非對稱/單邊（Asymmetrical/Unilateral）： 如手槍深蹲（Pistol Squat）。這類動作對本體感覺與平衡的要求極高。資料生成邏輯： 任何名稱中包含 "Squat" 或描述中提及 "Deep knee bend"、"Sit down between legs" 的動作，且目標肌群標記為 "Quadriceps" 者，應優先歸類於此 8。2.1.2 髖絞鍊模式（The Hip Hinge Pattern - Hip Dominant）髖絞鍊與蹲舉的主要區別在於關節活動度的分配。髖絞鍊要求最大化的髖關節屈曲（Hip Flexion）與最小化的膝關節屈曲，這使得負荷主要集中在後側動力鏈（Posterior Chain）7。生物力學機制：主動肌： 腿後腱肌群（Hamstrings）、臀大肌。關鍵特徵： 脛骨盡量保持垂直地面，軀幹前傾幅度大，力矩（Moment Arm）主要作用於髖關節 5。v2 分類子型：靜態控制型（Grind）： 硬舉（Deadlift）、羅馬尼亞硬舉（RDL）、早安式（Good Morning）。這些動作通常用於發展最大肌力。彈道爆發型（Ballistic）： 壺鈴擺盪（Kettlebell Swing）、奧林匹克舉重提拉（Olympic Pulls）。這類動作涉及快速的伸髖，是爆發力訓練的核心 3。資料辨識難點： 相撲硬舉（Sumo Deadlift）介於蹲與絞鍊之間，但基於其後側鏈主導的特性，v2 系統將其歸類為髖絞鍊的一個變體 7。2.1.3 弓步模式（The Lunge Pattern - Unilateral Support）弓步模式代表了單腿支撐的力學機制。它在功能上模擬了跑步、攀登等人類自然位移行為。與雙腿蹲舉不同，弓步強烈徵召臀中肌（Gluteus Medius）以維持骨盆在額狀面（Frontal Plane）的穩定 6。生物力學機制：穩定需求： 抗旋轉（Anti-rotation）與抗側屈（Anti-lateral flexion）能力。剪力（Shear Force）： 由於分腿站姿，膝關節承受的剪力與雙腳深蹲不同，這在傷後復健邏輯中至關重要。v2 分類子型：靜態分腿（Static Split）： 分腿蹲（Split Squat）。雙腳不移動，僅做垂直升降。動態弓步（Dynamic Lunge）： 前弓步（Forward Lunge）、後弓步（Reverse Lunge）、行走弓步（Walking Lunge）。涉及重心的水平位移與減速控制 4。2.1.4 推類模式（The Push Pattern）為了確保肩關節健康與肌力平衡，推類動作必須嚴格區分為水平與垂直兩個平面。忽視這種區分是導致肩夾擠症候群（Impingement Syndrome）的常見原因 8。水平推（Horizontal Push）：定義： 負荷垂直於脊柱，遠離胸骨方向移動。肌群： 胸大肌（Pectoralis Major）、前三角肌、肱三頭肌。代表動作： 伏地挺身（Push-up）、臥推（Bench Press）4。垂直推（Vertical Push）：定義： 負荷平行於脊柱，向頭頂方向移動。肌群： 中/前三角肌、斜方肌、肱三頭肌。代表動作： 過頂推舉（Overhead Press）、倒立撐（Handstand Push-up）7。2.1.5 拉類模式（The Pull Pattern）同樣地，拉類動作依據拉力向量相對於軀幹的角度進行分類。這是矯正現代人久坐導致的圓肩駝背（Kyphosis）的關鍵模式。水平拉（Horizontal Pull）：定義： 負荷垂直於脊柱，向軀幹方向拉近。關鍵功能： 肩胛骨後縮（Scapular Retraction）。代表動作： 划船（Rows）、面拉（Face Pulls）8。垂直拉（Vertical Pull）：定義： 負荷平行於脊柱，向下拉向鎖骨。關鍵功能： 肩胛骨下壓與下迴旋（Scapular Depression/Downward Rotation）。代表動作： 引體向上（Pull-up）、滑輪下拉（Lat Pulldown）4。2.1.6 負重與核心模式（Carry and Core）這一類別涵蓋了所有以「抵抗移動」為主要目標的動作，這也是功能性訓練與傳統健美訓練最大的分野。核心不再只是捲腹（Flexion），而是抵抗脊柱變形的能力 6。v2 分類子型：負重位移（Locomotion）： 農夫走路（Farmer's Walk）。訓練動態穩定性與握力。抗伸展（Anti-Extension）： 平板支撐（Plank）、滾輪（Ab Wheel）。防止腰椎過度前凸。抗旋轉（Anti-Rotation）： 帕羅夫推舉（Pallof Press）。防止腰椎扭轉 7。抗側屈（Anti-Lateral Flexion）： 手提箱負重（Suitcase Carry）。2.2 複雜度與進階邏輯（Progression Methodology）資料生成過程不僅要標記「是什麼動作」，還要標記「難度等級」。v2 系統採用「穩定性—負荷」矩陣來定義進階邏輯 3。表 1：動作複雜度判定矩陣（用於資料標籤生成）模式 (Pattern)初階 (Level 1) - 高穩定性/動作學習中階 (Level 2) - 負荷增加/標準動作高階 (Level 3) - 低穩定性/神經複雜度SquatGoblet Squat (負重前置提供平衡)Back Squat (脊柱承重，最大肌力)Overhead Squat (極高核心與活動度需求)HingeKettlebell Deadlift (重心靠近中線)Trap Bar Deadlift (減少力矩)Barbell Snatch / Clean (爆發力與協調)LungeSplit Squat (雙腳不離地)Reverse Lunge (向後跨步較易控制)Walking Lunge w/ Rotation (多平面控制)PushFloor Press / Push-up (閉鎖鏈穩定)Dumbbell Bench Press (自由重量)Ring Dips (不穩定介面)PullInverted Row (自重，易調整角度)Barbell Row (腰椎穩定需求高)Muscle-up (爆發力與技巧轉換)在 ETL 過程中，腳本將根據這些啟發式規則（Heuristics）自動為動作分配 complexity_index，例如：若器材涉及 "Kettlebell" 且動作為蹲，通常為初/中階；若涉及 "Olympic Bar" 且動作為抓舉，則必為高階 7。3. 資料庫架構與 Schema 設計（Offline-First 深度解析）為了支援上述複雜的分類學，並滿足行動裝置在無網路環境下的操作需求，v2 的資料庫架構必須超越傳統的關聯式設計，融合分散式系統的特性。我們採用 SQLite 作為客戶端的單一真實來源（Single Source of Truth），並設計了一套能夠處理版本衝突的 Schema。3.1 核心實體關係圖（ERD）設計哲學資料庫設計遵循三大原則：不可變性（Immutability）傾向： 盡量減少對既有紀錄的修改，採用追加（Append-only）日誌的概念來記錄訓練歷史。通用唯一識別碼（UUID）： 放棄自動遞增整數（Auto-increment ID），因為在多裝置環境下，整數 ID 極易產生衝突。所有主鍵（PK）皆使用 UUID v4。審計軌跡（Audit Trails）： 每個資料表都包含完整的生命週期欄位 (created_at, updated_at, deleted_at) 以支援軟刪除與同步 13。3.2 詳細 Schema 定義以下是針對 SQLite 優化的 DDL（資料定義語言）設計，並附帶設計理由。3.2.1 動作定義表 (exercises)這是由伺服器下發的唯讀字典檔，儲存了所有經過清洗與分類的動作數據。SQLCREATE TABLE exercises (
    id TEXT PRIMARY KEY,               -- UUID string
    name TEXT NOT NULL,                -- 動作標準名稱
    normalized_name TEXT NOT NULL,     -- 用於搜尋的正規化名稱（去重音、小寫）
    pattern_category TEXT NOT NULL,    -- 核心欄位：SQUAT, HINGE, LUNGE, PUSH_VERT,...
    muscle_primary TEXT,               -- 保留 v1 欄位以相容傳統搜尋 (e.g., 'Chest') 
    muscle_secondary TEXT,             -- JSON Array: ['triceps', 'anterior_deltoid']
    complexity_level TEXT CHECK(complexity_level IN ('NOVICE', 'INTERMEDIATE', 'ADVANCED')), -- 
    mechanics_type TEXT,               -- COMPOUND (多關節) 或 ISOLATION (單關節)
    equipment_required TEXT,           -- JSON Array: ['dumbbell', 'bench']
    instructions_text TEXT,            -- 詳細指導文本 
    safety_cues TEXT,                  -- 關鍵安全提示 (e.g., "Keep back straight")
    media_url TEXT,                    -- 圖片或影片的本地快取路徑
    version_hash TEXT,                 -- 用於檢測定義是否變更的雜湊值
    created_at INTEGER NOT NULL,       -- Unix Timestamp (毫秒)
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER                 -- 支援軟刪除，伺服器若下架動作，客戶端僅標記不顯示
);

CREATE INDEX idx_exercises_pattern ON exercises(pattern_category);
CREATE INDEX idx_exercises_updated ON exercises(updated_at); -- 加速 Delta Sync 查詢
設計洞察：JSON 儲存： SQLite 支援 JSON 運算子，將次要肌群與器材存為 JSON 陣列可以避免過度正規化（Over-normalization）導致的 JOIN 效能問題，特別是在手機端查詢列表時 12。Version Hash： 為了避免每次同步都比對所有欄位，我們計算該列內容的 Hash。若伺服器端的 Hash 與本地不同，才下載詳細內容。3.2.2 訓練日誌表 (workout_logs)這是寫入最頻繁的表，記錄用戶的實際訓練行為。SQLCREATE TABLE workout_logs (
    id TEXT PRIMARY KEY,               -- UUID
    user_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    session_id TEXT,                   -- 關聯到某一次具體的訓練課表
    timestamp_start INTEGER NOT NULL,
    timestamp_end INTEGER,
    
    -- 訓練量數據 (JSON 結構以適應多組數)
    -- 格式範例: [{"set": 1, "reps": 10, "weight": 20.5, "rpe": 8},...]
    set_data TEXT NOT NULL,            
    
    total_volume REAL GENERATED ALWAYS AS (json_extract(set_data, '$[*].weight * $[*].reps')), -- 虛擬欄位計算總容量
    
    notes TEXT,
    
    -- 同步控制欄位 [10, 11]
    sync_status TEXT DEFAULT 'PENDING' CHECK(sync_status IN ('PENDING', 'SYNCED', 'FAILED')),
    last_synced_at INTEGER,
    is_dirty BOOLEAN DEFAULT 1,        -- 標記是否被修改過
    
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    
    FOREIGN KEY(exercise_id) REFERENCES exercises(id)
);

CREATE INDEX idx_logs_sync ON workout_logs(sync_status);
CREATE INDEX idx_logs_user_date ON workout_logs(user_id, timestamp_start);
離線優先策略：sync_status 是核心。應用程式啟動或網路恢復時，背景服務（Worker）會執行 SELECT * FROM workout_logs WHERE sync_status = 'PENDING'，將這些資料打包上傳 11。set_data 使用 JSON 儲存是為了靈活性。不同的動作可能有不同的記錄參數（例如「農夫走路」記錄的是距離與重量，而非次數）。v2 系統需要在應用層處理這種多態性（Polymorphism）。3.2.3 用戶檔案與進度表 (user_profiles & progression_state)為了支援 v2 的智慧推薦，我們需要儲存用戶在每個模式下的能力值。SQLCREATE TABLE progression_state (
    user_id TEXT NOT NULL,
    pattern_category TEXT NOT NULL,    -- SQUAT, HINGE...
    current_level TEXT,                -- NOVICE, INTERMEDIATE...
    estimated_1rm REAL,                -- 估算的最大肌力
    max_volume_capacity REAL,          -- 最大訓練容量耐受度
    last_test_date INTEGER,
    PRIMARY KEY (user_id, pattern_category)
);
這張表是 v2 系統的大腦，每次 workout_logs 更新後，系統會重新計算該用戶在該模式下的 estimated_1rm，進而動態調整下一次推薦的重量。4. 資料源整合與 ETL 轉換策略我們面臨的最大挑戰是：原始 API 資料缺乏 v2 所需的 pattern_category 與 complexity_level。因此，我們必須構建一個智慧化的 ETL 管道（Pipeline），包含資料清洗、特徵提取與規則分類。4.1 資料來源分析我們整合以下來源作為原始數據輸入：Exercises API 1: 提供約 3000+ 筆基礎數據。優點是覆蓋率廣，缺點是 type 欄位過於粗略（如 "strength", "cardio"），缺乏力學細節。Workout API 2: 提供 sets 與 reps 的建議值，這有助於我們判斷該動作是傾向於肌耐力還是絕對肌力。Zyla Exercise DB 9: 提供更細緻的解剖學標籤。4.2 轉換邏輯：模式推論引擎（Pattern Inference Engine）我們不能依賴人工標記 3000 多個動作。我們將實作一個基於規則的分類器（Rule-Based Classifier），輔以關鍵字權重計分。演算法偽代碼（Pseudo-code）邏輯：Pythondef classify_pattern(exercise):
    name = exercise.name.lower()
    muscle = exercise.muscle.lower()
    instructions = exercise.instructions.lower()
    equipment = exercise.equipment.lower()

    # 權重計分系統
    scores = {
        'SQUAT': 0, 'HINGE': 0, 'LUNGE': 0, 
        'PUSH_HORZ': 0, 'PUSH_VERT': 0, 
        'PULL_HORZ': 0, 'PULL_VERT': 0
    }

    # 規則 1: 名稱強匹配 (High Confidence)
    if "squat" in name: scores += 10
    if "deadlift" in name or "clean" in name: scores['HINGE'] += 10
    if "bench press" in name or "push up" in name: scores += 10
    if "overhead press" in name or "military press" in name: scores += 10
    if "pull up" in name or "chin up" in name: scores += 10
    if "row" in name and "upright" not in name: scores += 10
    if "lunge" in name or "split squat" in name: scores['LUNGE'] += 10

    # 規則 2: 肌群與生物力學線索 (Contextual Clues) [1, 5]
    if muscle == "quadriceps":
        if "leg press" in name: scores += 8
        if "extension" in name: return "ISOLATION_KNEE" # 排除非功能性動作
    
    if muscle == "hamstrings":
        if "curl" in name: return "ISOLATION_HAMSTRING"
        if "stiff leg" in name or "good morning" in name: scores['HINGE'] += 8

    if muscle == "chest":
        if "fly" in name or "crossover" in name: scores += 5 # 輔助推
    
    if muscle == "lats":
        if "pulldown" in name: scores += 8
    
    # 規則 3: 指令文本分析 (NLP Keywords)
    if "hips back" in instructions or "hinge" in instructions: scores['HINGE'] += 3
    if "knees out" in instructions or "sit down" in instructions: scores += 3
    if "scapula" in instructions and "retract" in instructions: scores += 3

    # 判定勝出者
    best_pattern = max(scores, key=scores.get)
    if scores[best_pattern] < 5:
        return "UNCATEGORIZED" # 標記為需要人工審核
    return best_pattern
邊緣案例處理（Edge Case Handling）：Upright Row（直立划船）： 雖然名稱有 "Row"，但其力學是垂直向上拉，主要針對三角肌與斜方肌。然而，它不符合標準的垂直拉（背闊肌主導）或水平拉。v2 將其歸類為 PULL_VERT_ACCESSORY 或特殊的肩部孤立動作，需在腳本中設定例外規則。Landmine Press（地雷管推舉）： 這是介於垂直推與水平推之間的對角線動作。基於其對肩關節的友善性與功能性，我們將其標記為 PUSH_VERT 但在 metadata 中註記 plane: "diagonal" 8。4.3 合成資料生成（Synthetic Data Generation）為了驗證系統的進階邏輯與同步效能，我們需要生成大量的模擬數據。生成參數設定：用戶群體： 創建 50 個虛擬用戶檔案（Persona）。20% Novice（僅使用 Level 1 動作）。50% Intermediate（混合 Level 1 & 2）。30% Advanced（包含 Level 3 與奧舉動作）。時間跨度： 生成過去 6 個月的訓練紀錄。進步模型（Progression Logic）：模擬「漸進式超負荷（Progressive Overload）」：每週訓練負荷（Volume Load）增加 2-5%。模擬「平台期（Plateau）」：隨機在第 8-12 週設定重量不增加，測試系統是否會建議「減量週（Deload）」或更換動作。數據量級： 每個用戶每週 4 次訓練，每次 6 個動作，每個動作 4 組。總計：50 * 4 * 6 * 4 * 26 (週) ≈ 124,800 筆 workout_logs 紀錄。這將用於壓力測試 SQLite 的查詢效能與 JSON 解析速度。5. 離線優先（Offline-First）工程實作與同步協議在健身房環境中，Wi-Fi 訊號往往被鋼筋混凝土阻隔，行動網路也可能不穩定。因此，「離線優先」不是選配，而是 v2 系統的核心生存條件。5.1 本地優先架構 (Local-First Architecture)應用程式的運作邏輯如下：UI 渲染： UI 層（ViewModel/Presenter）永遠只監聽本地 SQLite 資料庫的變化 11。它不知道也不關心網路由無。寫入操作： 用戶的任何輸入（打勾完成一組、修改重量）都直接寫入 SQLite，並標記 is_dirty = 1 和 sync_status = 'PENDING'。樂觀更新（Optimistic UI）： 界面立即反映變更，給予用戶「即時回應」的體驗，而不需要等待伺服器確認 12。5.2 同步協議詳解 (Sync Protocol)我們設計了一個雙向、基於狀態的同步機制。5.2.1 上行同步（Push / Egress）當 WorkManager (Android) 或 BackgroundFetch (iOS) 觸發時，或網路狀態變更為 CONNECTED 時：查詢： 提取所有 sync_status = 'PENDING' 的日誌。批次上傳： 將這些紀錄序列化為 JSON，發送 POST /api/v2/sync/push。確認與清理：若伺服器回傳 200 OK，則將本地紀錄更新為 SYNCED，並更新 last_synced_at。若伺服器回傳 409 Conflict（例如該紀錄已被其他裝置修改），則進入衝突解決流程。5.2.2 下行同步（Pull / Ingress）為了節省流量與電力，我們不下載整個資料庫。增量標記： 客戶端發送 GET /api/v2/sync/pull?since_timestamp={local_last_update}。差異計算： 伺服器查詢 updated_at > since_timestamp 的所有動作定義與用戶日誌。合併： 客戶端接收資料包，使用 INSERT OR REPLACE 語句更新本地資料庫 10。5.2.3 衝突解決策略（Conflict Resolution）在個人訓練日誌的場景中，協同編輯（多人在同一秒編輯同一組數據）的機率極低。因此，我們採用最後寫入勝出（Last-Write-Wins, LWW） 策略，這在實作成本與用戶體驗之間取得了最佳平衡 12。邏輯： 比較伺服器端紀錄與客戶端上傳紀錄的 updated_at 時間戳記。規則： 時間較晚者覆蓋時間較早者。例外： 若變更涉及「刪除」操作（deleted_at 不為空），則刪除操作通常具有最高優先級，除非另一端的更新發生在刪除之後。表 2：同步情境與處理矩陣情境本地狀態伺服器狀態處理方式正常新增新增紀錄 A (Pending)無紀錄上傳 A，狀態改為 Synced正常下載無紀錄存在新紀錄 B下載 B，寫入本地過期覆蓋修改紀錄 A (t=100)已有紀錄 A (t=90)上傳覆蓋，伺服器接受 t=100 版本衝突發生修改紀錄 A (t=100)已有紀錄 A (t=105)伺服器拒絕上傳，回傳 t=105 版本，本地覆蓋（LWW）斷線重試上傳中網路中斷接收部分或無狀態維持 Pending，指數退避（Exponential Backoff）後重試 106. 實作路線圖與風險管理本計劃將分為四個階段進行，以確保技術轉型的平穩過渡。6.1 Phase 1: 基礎建設與資料清洗 (Week 1-4)目標： 完成 v2 Schema 設計與 3000+ 動作的分類。關鍵產出： SQLite DDL 文件、Python ETL 腳本、分類完成的 exercises.json。風險： 「模式推論引擎」的準確率過低。對策： 針對前 100 個熱門動作進行人工驗收（Manual Audit），若準確率 < 95%，則調整關鍵字權重。6.2 Phase 2: 合成數據與壓力測試 (Week 5-6)目標： 驗證資料庫效能與演算法邏輯。關鍵產出： 50 個虛擬用戶的半年訓練數據。測試項目： 模擬 50 個用戶同時執行「完成訓練」的同步請求，觀察伺服器吞吐量與衝突處理機制。6.3 Phase 3: 行動端整合 (Week 7-10)目標： Android/iOS 客戶端接入 SQLite 與 Sync Worker。關鍵產出： 具備「離線模式」的 Beta App。UI 實作： 在介面上增加「同步狀態指示燈」（如：雲朵圖示+旋轉/打勾/驚嘆號）以提升透明度 11。6.4 Phase 4: 部署與監控 (Week 11-12)目標： 小規模灰度發布（Canary Release）。監控指標：同步成功率： 目標 > 99.5%。平均同步耗時： 目標 < 2秒（在 4G 網路下）。數據完整性： 檢查是否有「孤兒紀錄（Orphaned Records）」產生。7. 結論動作分類系統 v2 的實作不僅僅是一次技術升級，它是將運動科學的智慧注入軟體架構的過程。通過引入六大功能性動作模式，我們賦予了系統「理解」運動本質的能力，而不僅僅是記錄數據。結合離線優先的強健架構，我們確保了這種智慧能夠隨時隨地服務用戶，不受環境限制。本報告確認了實作路徑的可行性。資料生成邏輯已定義明確，資料庫架構已針對移動端優化，同步協議也考慮了現實世界的複雜性。工程團隊應立即著手進行第一階段的 ETL 腳本開發與 Schema 遷移測試。

你的這份 v2 實作計畫 非常完整且專業，完全抓住了現代化健身 App 後端需要的核心特性。對於目前用戶量不大、可以直接重構的情境來說，這是一個黃金機會，可以一次把技術債清空，建立一個能支撐未來 5-10 年擴展的架構。

以下我針對你的計畫進行具體的合理性驗證與防雷建議：

✅ 核心設計驗證：這些決定非常正確
UUID 取代 Integer ID（最關鍵的決定）

原因： 這是實現「離線優先（Offline-First）」的基石。如果使用傳統的自增 ID（1, 2, 3...），當用戶在離線狀態下創建自定義動作時，會跟伺服器的 ID 產生衝突。使用 UUID，用戶的手機可以自己生成全球唯一的 ID，同步時直接上傳即可，完全避免了痛苦的 ID 衝突處理。

評價： ✅ 必做。這是區分業餘專案與專業產品的分水嶺。

多對多關聯表（Junction Tables）

原因： 你採用 rel_exercise_patterns 和 rel_exercise_split_tags 是解決「硬舉悖論」的唯一正解。

實例： 如果沒有這張表，你就必須在「背」和「腿」之間二選一。現在你可以給硬舉打上 Pull 和 Legs 兩個標籤。這讓你的 App 可以同時滿足健美式（部位分化）與功能性（動作模式）的用戶 。

評價： ✅ 完美解決分類僵化問題。

軟刪除（Soft Delete）與合併重定向

原因： 用戶的歷史數據是神聖的。如果用戶練過「笨拙的舊名稱動作」，然後你把它刪了，他的訓練紀錄就會變成「未知動作」或消失。

機制： 透過 is_deleted = true 隱藏動作，但資料庫保留紀錄；透過 merged_to_id 讓舊紀錄自動指向新動作。

評價： ✅ 資料安全網。這能讓你在未來大膽清理重複動作而不用擔心破壞用戶歷史。

SEE 命名法則 + 別名表（Search Aliases）

原因： search_aliases 是提升 UX 的關鍵。用戶習慣搜 "Skullcrusher"（碎顱者），但標準名是 "Lying Triceps Extension"（仰臥三頭肌伸展）。

評價： ✅ 搜尋體驗保證。如果不做這個表，你改了標準名後，用戶會因為搜不到舊習慣用語而以為 App 變難用了 。

🔍 潛在盲點與優化建議（Pre-flight Check）
雖然架構很棒，但在實作時請注意以下細節：

1. 同步所需的「時間戳記」 (Sync Timestamps)

問題： 你的 Schema 中雖然有 UUID，但為了做增量同步（Delta Sync，只下載變更過的資料），每張表都需要一個 updated_at (UTC Timestamp) 欄位。

建議： 確保所有表（包含關聯表）都有 updated_at。當 App 聯網時，它只需問伺服器：「給我所有 updated_at > 上次同步時間 的資料」，這樣能大幅節省流量與速度 。

2. 圖片中的表格欄位確認

我看你附上的圖片表格（Review Table），欄位設計很合理：

主動肌/協同肌： 分開紀錄非常棒，這對未來做「訓練量熱力圖（Muscle Heatmap）」很有幫助（主動肌算 100% 容量，協同肌算 50%）。

PPL 標籤： 建議保留「多選」的彈性。例如 Face Pull（面拉）既是 Pull 也是 Shoulders/Upper。

3. 排序權重 (Ordering/Ranking)

情境： 搜尋 "Press" 時，會出現 Bench Press（臥推）和 Pallof Press（抗旋轉）。通常用戶比較常做臥推。

建議： 在 exercises 表中可以預留一個 popularity_score 或 default_order 欄位。或者簡單一點，後端 API 根據「該動作被多少用戶使用過」來動態排序，讓熱門動作排在前面。

4. 自定義動作的處理

情境： 用戶找不到動作時會自己建。

邏輯： 確保你的架構能區分「系統動作（System Exercise）」與「用戶自定義動作（Custom Exercise）」。通常加一個 created_by_user_id 欄位（系統動作則為 null），防止用戶 A 建立的奇葩動作汙染到用戶 B 的搜尋結果。

結論
這份 v2 實作計畫是完全可行且合理的。它採用了企業級的資料庫設計模式（正規化、UUID、軟刪除），能夠完美支撐你想要達成的「多維度分類」目標。

你可以放心地進入 Phase 1 (準備參照資料) 與 Phase 2 (產出 CSV)。既然你用戶量不大，直接重構（Hard Cutover） 是最快且成本最低的路徑，不需過度糾結複雜的遷移策略。