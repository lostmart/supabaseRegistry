-- Migration: seed_qcm_fr
-- Seeds 20 training questions from the qcm-fr.json dataset.
-- Source file: docs/qcm-fr.json (excercideData.id = "qcm-fr-civique")
-- All questions are CSP level (available to all authenticated users).
-- question_type: 'situational' for examType "Mise en situation", 'knowledge' for all others.
-- options JSONB format: [{"label":"A","text_fr":"..."},{"label":"B","text_fr":"..."},...]
-- correct_answer: label string ("A", "B", "C", or "D")

INSERT INTO questions (
  id, theme_id, exam_type, question_type,
  question_text_fr, options, correct_answer, explanation_fr, difficulty
) VALUES

-- Q1 | theme: dd | Droits et devoirs
(
  'q_csp_dd_k_001', 'dd', 'CSP', 'knowledge',
  'En France, est-il possible d''adhérer librement à un parti politique ?',
  '[
    {"label":"A","text_fr":"Non, les partis politiques sont réservés aux élus"},
    {"label":"B","text_fr":"Oui, mais seulement avec l''autorisation de l''État"},
    {"label":"C","text_fr":"Oui, c''est un droit fondamental"},
    {"label":"D","text_fr":"Non, sauf pour les partis au pouvoir"}
  ]'::jsonb,
  'C',
  'La liberté d''association permet à tout citoyen d''adhérer au parti politique de son choix.',
  2
),

-- Q2 | theme: inst | Système institutionnel et politique
(
  'q_csp_inst_k_001', 'inst', 'CSP', 'knowledge',
  'Qui est responsable de la gestion des collèges publics en France ?',
  '[
    {"label":"A","text_fr":"L''État"},
    {"label":"B","text_fr":"La région"},
    {"label":"C","text_fr":"Le département"},
    {"label":"D","text_fr":"La commune"}
  ]'::jsonb,
  'C',
  'Les départements ont la charge spécifique de la gestion des collèges.',
  2
),

-- Q3 | theme: inst
(
  'q_csp_inst_k_002', 'inst', 'CSP', 'knowledge',
  'Qui gère les écoles primaires et maternelles publiques ?',
  '[
    {"label":"A","text_fr":"L''État"},
    {"label":"B","text_fr":"La région"},
    {"label":"C","text_fr":"Le département"},
    {"label":"D","text_fr":"La commune"}
  ]'::jsonb,
  'D',
  'La gestion des écoles primaires et maternelles relève de la compétence de la commune.',
  2
),

-- Q4 | theme: inst
(
  'q_csp_inst_k_003', 'inst', 'CSP', 'knowledge',
  'Comment les maires sont-ils désignés en France ?',
  '[
    {"label":"A","text_fr":"Élus au suffrage universel direct"},
    {"label":"B","text_fr":"Nommés par le Préfet"},
    {"label":"C","text_fr":"Élus par le conseil municipal"},
    {"label":"D","text_fr":"Choisis par le Président de la République"}
  ]'::jsonb,
  'C',
  'Les conseillers municipaux élisent le maire parmi eux après les élections municipales.',
  2
),

-- Q5 | theme: inst
(
  'q_csp_inst_k_004', 'inst', 'CSP', 'knowledge',
  'Quelle collectivité territoriale organise les transports régionaux ?',
  '[
    {"label":"A","text_fr":"La commune"},
    {"label":"B","text_fr":"Le département"},
    {"label":"C","text_fr":"La région"},
    {"label":"D","text_fr":"L''État"}
  ]'::jsonb,
  'C',
  'L''organisation des transports à l''échelle régionale est une mission de la région.',
  2
),

-- Q6 | theme: vie | Vivre dans la société française
(
  'q_csp_vie_k_001', 'vie', 'CSP', 'knowledge',
  'À quel âge est fixée la majorité numérique permettant de s''inscrire seul sur les réseaux sociaux ?',
  '[
    {"label":"A","text_fr":"13 ans"},
    {"label":"B","text_fr":"15 ans"},
    {"label":"C","text_fr":"18 ans"},
    {"label":"D","text_fr":"16 ans"}
  ]'::jsonb,
  'B',
  'Le RGPD fixe cet âge à 15 ans en France pour consentir seul au traitement de ses données.',
  2
),

-- Q7 | theme: dd
(
  'q_csp_dd_k_002', 'dd', 'CSP', 'knowledge',
  'En France, la conduite d''une moto sans permis est considérée comme :',
  '[
    {"label":"A","text_fr":"Une simple infraction au code de la route"},
    {"label":"B","text_fr":"Un délit pénal"},
    {"label":"C","text_fr":"Une contravention"},
    {"label":"D","text_fr":"Autorisée si la puissance est faible"}
  ]'::jsonb,
  'B',
  'C''est un délit sanctionné par des peines d''amende et d''emprisonnement devant le tribunal correctionnel.',
  2
),

-- Q8 | theme: dd
(
  'q_csp_dd_k_003', 'dd', 'CSP', 'knowledge',
  'En quoi consiste principalement le devoir de solidarité ?',
  '[
    {"label":"A","text_fr":"À payer ses dettes personnelles"},
    {"label":"B","text_fr":"À participer à l''effort collectif (impôts) et aux difficultés d''autrui"},
    {"label":"C","text_fr":"À respecter le code de la route"},
    {"label":"D","text_fr":"À servir dans l''armée uniquement"}
  ]'::jsonb,
  'B',
  'Il s''agit de contribuer aux charges de la nation selon ses moyens.',
  2
),

-- Q9 | theme: hist | Histoire, géographie et culture
(
  'q_csp_hist_k_001', 'hist', 'CSP', 'knowledge',
  'Quel plat emblématique est une spécialité du sud-ouest de la France ?',
  '[
    {"label":"A","text_fr":"La paella"},
    {"label":"B","text_fr":"Le couscous"},
    {"label":"C","text_fr":"Le cassoulet"},
    {"label":"D","text_fr":"Les sushis"}
  ]'::jsonb,
  'C',
  'Le cassoulet est un plat traditionnel français à base de haricots blancs et de viandes.',
  1
),

-- Q10 | theme: hist
(
  'q_csp_hist_k_002', 'hist', 'CSP', 'knowledge',
  'Qui a peint le célèbre tableau ''La liberté guidant le peuple'' ?',
  '[
    {"label":"A","text_fr":"Jacques-Louis David"},
    {"label":"B","text_fr":"Eugène Delacroix"},
    {"label":"C","text_fr":"Gustave Courbet"},
    {"label":"D","text_fr":"Théodore Géricault"}
  ]'::jsonb,
  'B',
  'Ce tableau a été peint en 1830 pour célébrer la révolution des Trois Glorieuses.',
  2
),

-- Q11 | theme: hist
(
  'q_csp_hist_k_003', 'hist', 'CSP', 'knowledge',
  'Dans quel musée parisien peut-on admirer la Joconde ?',
  '[
    {"label":"A","text_fr":"Le Musée d''Orsay"},
    {"label":"B","text_fr":"Le Musée national d''art moderne"},
    {"label":"C","text_fr":"Le Musée du Louvre"},
    {"label":"D","text_fr":"Le Musée de l''Orangerie"}
  ]'::jsonb,
  'C',
  'L''œuvre de Léonard de Vinci est exposée au Musée du Louvre.',
  1
),

-- Q12 | theme: hist
(
  'q_csp_hist_k_004', 'hist', 'CSP', 'knowledge',
  'Où se trouve la célèbre grotte abritant des peintures préhistoriques ?',
  '[
    {"label":"A","text_fr":"Val de Loire"},
    {"label":"B","text_fr":"Grotte de Lascaux"},
    {"label":"C","text_fr":"Carnac"},
    {"label":"D","text_fr":"Catacombes de Paris"}
  ]'::jsonb,
  'B',
  'La grotte de Lascaux en Dordogne contient des peintures datant du Paléolithique.',
  1
),

-- Q13 | theme: hist
(
  'q_csp_hist_k_005', 'hist', 'CSP', 'knowledge',
  'Quel peintre est l''auteur de la série monumentale des ''Nymphéas'' ?',
  '[
    {"label":"A","text_fr":"Paul Cézanne"},
    {"label":"B","text_fr":"Pierre-Auguste Renoir"},
    {"label":"C","text_fr":"Edgar Degas"},
    {"label":"D","text_fr":"Claude Monet"}
  ]'::jsonb,
  'D',
  'Claude Monet a peint ces œuvres dans son jardin à Giverny.',
  2
),

-- Q14 | theme: vie
(
  'q_csp_vie_k_002', 'vie', 'CSP', 'knowledge',
  'Que célèbre-t-on en France le 1er mai ?',
  '[
    {"label":"A","text_fr":"La fête nationale"},
    {"label":"B","text_fr":"La victoire de 1945"},
    {"label":"C","text_fr":"La fête du Travail"},
    {"label":"D","text_fr":"L''arrivée du printemps"}
  ]'::jsonb,
  'C',
  'Le 1er mai est la journée internationale des travailleurs et un jour férié.',
  1
),

-- Q15 | theme: vie
(
  'q_csp_vie_k_003', 'vie', 'CSP', 'knowledge',
  'Qu''est-ce que le SMIC ?',
  '[
    {"label":"A","text_fr":"Le salaire moyen en France"},
    {"label":"B","text_fr":"Le salaire maximum horaire"},
    {"label":"C","text_fr":"Le salaire minimum horaire légal"},
    {"label":"D","text_fr":"Le revenu de solidarité active"}
  ]'::jsonb,
  'C',
  'Le Salaire Minimum de Croissance est le montant horaire brut minimal légal.',
  1
),

-- Q16 | theme: vie
(
  'q_csp_vie_k_004', 'vie', 'CSP', 'knowledge',
  'Qui peut demander un congé parental d''éducation en France ?',
  '[
    {"label":"A","text_fr":"La mère uniquement"},
    {"label":"B","text_fr":"Le père uniquement"},
    {"label":"C","text_fr":"Un des parents salarié, sans condition de sexe"},
    {"label":"D","text_fr":"Les grands-parents uniquement"}
  ]'::jsonb,
  'C',
  'Tout parent salarié peut y prétendre suite à une naissance ou une adoption.',
  2
),

-- Q17 | theme: vie
(
  'q_csp_vie_k_005', 'vie', 'CSP', 'knowledge',
  'Une femme peut-elle créer et diriger une entreprise en France ?',
  '[
    {"label":"A","text_fr":"Non, sans l''autorisation de son mari"},
    {"label":"B","text_fr":"Oui, mais uniquement si elle est célibataire"},
    {"label":"C","text_fr":"Oui, dans les mêmes conditions qu''un homme"},
    {"label":"D","text_fr":"Oui, mais elle ne peut pas être dirigeante"}
  ]'::jsonb,
  'C',
  'Les femmes ont la pleine capacité juridique pour créer et diriger des entreprises.',
  2
),

-- Q18 | theme: dd | examType: Mise en situation → situational
(
  'q_csp_dd_s_001', 'dd', 'CSP', 'situational',
  'Le refus de payer ses impôts pour protester est-il légal ?',
  '[
    {"label":"A","text_fr":"Oui, c''est une forme d''expression politique"},
    {"label":"B","text_fr":"Oui, car l''impôt est volontaire"},
    {"label":"C","text_fr":"Non, car l''impôt est un devoir constitutionnel obligatoire"},
    {"label":"D","text_fr":"Non, sauf si la majorité décide de le faire"}
  ]'::jsonb,
  'C',
  'Le paiement de l''impôt est inconditionnel et le refus est un délit fiscal.',
  3
),

-- Q19 | theme: dd | examType: Mise en situation → situational
(
  'q_csp_dd_s_002', 'dd', 'CSP', 'situational',
  'Le devoir de participer à la JDC s''applique-t-il à un étranger naturalisé ?',
  '[
    {"label":"A","text_fr":"Non, cela ne concerne que les Français de naissance"},
    {"label":"B","text_fr":"Oui, car tout citoyen doit concourir à la défense nationale"},
    {"label":"C","text_fr":"Non, les naturalisés en sont exemptés"},
    {"label":"D","text_fr":"Oui, mais seulement s''il a plus de 25 ans"}
  ]'::jsonb,
  'B',
  'Tous les citoyens, par naissance ou naturalisation, partagent les mêmes devoirs de défense.',
  3
),

-- Q20 | theme: dd | examType: Mise en situation → situational
(
  'q_csp_dd_s_003', 'dd', 'CSP', 'situational',
  'Une personne gardée à vue a-t-elle droit à un avocat dès le début ?',
  '[
    {"label":"A","text_fr":"Oui, c''est un droit garanti dès le début de la mesure"},
    {"label":"B","text_fr":"Non, seulement si l''enquête est terminée"},
    {"label":"C","text_fr":"Oui, mais seulement si elle avoue"},
    {"label":"D","text_fr":"Non, l''avocat n''est là que devant le juge"}
  ]'::jsonb,
  'A',
  'L''assistance d''un avocat est un droit effectif dès le début de la garde à vue.',
  3
);
