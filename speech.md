# Вступление

Коллеги, добрый день. Вашему вниманию предлагается доклад «GraphQL как способ организации
back-end API».

В данном докладе я хотел бы дать краткий обзор технологии GraphQL. А именно - на простых примерах показать, какие
проблемы решает GraphQL и чем он может быть вам полезен. Сразу скажу, что обзор будет довольно поверхностным. Те, кто
знаком с этой технологией, наверное не найдут для себя ничего нового. В презентации доклада будут ссылки в виде QR
кодов, и те, кто заинтересовался, могут делать скриншоты. Впрочем, если кто не успеет или пропустит интересный слайд, не
переживайте, в конце я дам ссылку на исходники данной презентации.

# Введение

Доклад я начну с краткого введения в технологию. Далее я расскажу о том, чем GraphQL может помочь в многосервисных
приложениях. Также упомяну о некоторых проблемах данной технологии и совсем коротко пробегусь по имеющимся
решениям на основе этой технологии.

GraphQL - формально - это спецификация, документ, которая включает в себя язык запросов, язык описания схем и другие
элементы. Изначально она была создана инженерами компании Facebook в 2012 году. Спустя несколько лет технология была
отдана сообществу и в настоящее время её развитием занимается некоммерческая организация GraphQL Foundation.

GraphQL был создан, как мне кажется, для того, чтобы решить типичные проблемы типичного RESTful API. Поэтому давайте
сразу и обратимся к такому API и посмотрим на его проблемы и на то, как их решает GraphQL.

# Проблемы RESTful API

Рассмотрим в качестве примера некое API, которое возвращает данные кадрового отдела. API состоит из трёх точек входа,
которые возвращают информацию о филиалах предприятия, их дочерних отделах и сотрудниках, каждый из которых работает в
одном из филиалов. Как мы видим, каждая точка входа возвращает плоские объекты без избыточных полей, что делает наше API
полностью нормализованным. Также отметим, что на стороне back-end такое API реализуется при помощи простых операций,
таких как выбор одиночного объекта по его идентификатору и выборка нескольких однотипных объектов по списку
идентификаторов.

Теперь нам необходимо решить следующую задачу: по известному идентификатору сотрудника получить название
филиала, в котором он работает.

Если оставаться в рамках данного API, не менять его, то для решения задачи нужно выполнить три последовательных запроса
к back-end. Такое решение имеет известные проблемы. Во-первых, общее время операции вырастет примерно втрое. Заметим,
что иногда время отклика, например, мобильного приложения, является важной частью его удобства для пользователей.
Во-вторых, клиентский код заметно усложняется, как минимум в силу утроения логики по обработке результатов запроса к
серверу. В-третьих, есть опасность получения несогласованных данных.

Можно модифицировать API путём его денормализации, добавил дополнительные поля в тип Employee. Иногда это просто и
оправданное решение. Но оно довольно частное, нет ли более общего решения?

Да, есть. Мы можем добавить информацию об отделе и его филиале непосредственно в данные сотрудника. Конечно, добавил при
этом дополнительные параметры в наше API для того, чтобы данные отдела и филиала отправлялись клиенту только тогда,
когда они точно нужны. При этом тип Employee перестал быть «плоским», в нём появились иерархичные данные.

Наше решение имеет следующий недостаток: сервер отправляет клиенту много лишних данных. Нам нужно только название
филиала, а мы кроме этого получаем несколько ненужным полей включая, между прочим, фотографию сотрудника - поле, которое
может быть весьма тяжёлым как для сервера, так и для клиента, не говоря уже о повышенном расходе трафика.

Поэтому мы добавим в наше API ещё несколько параметров, которые отключают отправку полей, которые нам не нужны в данный
момент. В результаты мы получили название филиала в результате одного запроса к сереру и в составе компактного пакета
данных.

Итак, задача решена и причём эффективным образом. Но по мере решения подобных однотипных задач начинают копиться другие
проблемы.

С точки зрения клиента, наше API стало весьма громоздким. Клиенту нужно помнить или записывать множество
конфигурационных параметров. А если в API добавятся какие-нибудь новые поля? Их ведь тоже надо будет как-то отключать?
То есть, чтобы поддерживать эффективность работы, клиенту необходимо отслеживать изменения в API.

С точки зрения сервера всё ещё хуже. Все это обилие конфигурационных параметров нужно поддерживать, а значит наша
бизнес-логика будет весьма зашумлена кодом, отвечающим за возврат данных клиенту. И сама бизнес-логика усложнилась, в
дополнение к операциям по выборке данных добавилась логика композиции.

Как мы видим, возникает запрос на какое-нибудь общее решение. Разрабочику на стороне клиента хотелось бы не запоминать
кучу
параметров, а иметь какой-нибудь простой набор правил по выбору нужных полей. То есть, нужен некий язык запросов. С
другой стороны, back-end разработчику хотелось бы иметь библиотеку или фреймворк, которые взяли бы на себя всю рутинную
работу по разбору этого языка, по композиции данных и так далее.

# Решаем проблемы при помощи GraphQL

GraphQL как раз и призван решить эти проблемы.

Давайте посмотрим, как это может выглядеть на стороне клиента. Слева - пример GraphQL запроса. В нём мы указываем имя
запроса, его параметры и перечисляем поля, которые нам нужно получить от сервера. Справа - результат запроса. Как видно,
сервер прислал нам ровно то, что мы просили, ни одного лишнего поля. Разработчику не надо помнить названия параметров,
достаточно изучить весьма простой язык запросов.

А что на сервере? А на сервере основную работу на себя взял фреймворк.

Разработчику на back-end остаётся написать небольшие процедуры, в GraphQL они называются резольверы. В данном случае
наши резольверы будут просто искать отдельный плоский объект по его идентификатору. Ну или несколько однотипных объектов
по списку идентификаторов. Вы заметили, что на back-end мы опять вернулись к тому же самому, что было в изначальному
RESTful API?

Реализация на back-end осталась простой, даже тривиальной. Зато у клиентов появился довольно мощный язык запросов.

Или вот ещё пример GraphQL запроса. Мы в одном обращении к серверу запрашиваем три объекта разных типов.

Итак, с использованием GraphQL жизнь разработчика клиентов (а это зачастую front-end разработчики, но не только) засияла
новыми красками.

Также GraphQL упрощает жизнь системному аналитику. Вспомним типичный современный проект: Agile во все поля, итерационная
разработка, список требований зачастую неполный. В общем, проектировать API приходится в ситуации полной
неопределённости. И в такой ситуации хочется заложить в API максимальную возможную гибкость. С GraphQL это довольно
просто: мы определяем типы объектов, связи между ними и основные операции. А вот комбинация выборки объектов уже не наша
головная боль, это всё отдаётся на откуп клиентам API.

Но сразу заметим, что GraphQL лучше всего работает в типичных web-приложениях, таких как тот же самый Facebook. В
некоторых специфичных случаях GraphQL может оказаться бесполезным.

# Коротко о GraphQL

Но вернёмся к GraphQL. Помимо собственно QL - языка запросов - в нём есть специальный язык описания схем, так называемый
SDL. На этом языке пишут так называемую схему, то есть полное описание вашего API.

В самом простом случае схема состоит из следующих элементов. Это типы объектов, связи между типами, операции чтения
данных с сервера и операции изменения данных на сервере.

Схема описывает API исчерпывающим образом. И эта информация нужна клиентам вашего API. Для этого в GraphQL есть механизм
интроспекции. Это стандартный способ получить информацию об элементах API через само API. Например, следующим запросом
мы получаем список полей у объекта типа Employee.

Схема может содержать текстовую документацию. И эта документация, в отличие от комментариев, доступна через
интроспекцию, то есть является полноценной частью API.

Также схема может содержать пользовательские метаданные с произвольной семантикой. Например, в данном примере мы даём
понять, что поле numOfLogins доступно только пользователям, имеющим роль администратора. Это наша пользовательская
директива, и её наполнение реализуется на стороне back-end.

Любое API меняется со временем. А жизненный цикл вашего back-end и ваших клиентов может весьма различаться. Поэтому в
REST считается хорошей практикой фиксировать версии вашего API, когда изменения в них становятся обратно несовместимыми.
При этом клиенту нужно явно указать нужную версию, а серверу нужно поддерживать всё актуальные версии.

В случае GraphQL, конечно, никто не запрещает вам иметь несколько версий схем и держать на сервере несколько реализаций.
Но официальной best practice является то, что в документации зовётся continuous evolution. Эта эволюция включает три
принципа:

Во-первых, нельзя менять семантику и формат существующих элементов API. Это очевидное требование, оно и в REST такое же.

А вот второй принцип характерен именно для GraphQL: мы, как правило, можем спокойно, не опасаясь поломать клиентов,
добавлять новые элементы в наше API. Просто потому, что клиенты о них не узнают, пока явно их не запросят.

Ну и третий принцип: устаревшие элементы API помечаем как deprecated. Дальше уже забота клиентов вовремя это обнаружить
и перейти на новые элементы. Как долго deprecated поля будут оставаться в API - это уже дело конкретного проекта и его
политики.

# GraphQL в многосервисной среде

У меня нет цели, да и времени подробно рассказать о всех фишках GraphQL. Всё, что я успел рассказать выше, касается
простых приложений, состоящих из одного back-end модуля. В наше время такие приложения уже редкость, как правило
современное приложение состоит из многих компонентов, часть которых предоставляет своё API. Давайте посмотрим, какие
особые возможности для таких приложений есть в GraphQL.

Вернёмся к нашему приложению с API кадрового отдела. Только на этот раз это уже многомодульное приложение. Здесь каждый
модуль работает с объектами лишь одного типа. Каждый модуль имеет свою схему. Как видно из диаграммы, клиент имеет связи
с каждых из модулей.

В чём тут неудобство? Во-первых, клиенту нужно держать список адресов и схем и знать, куда обращаться в каждом случае.
Но это ещё терпимо. Хуже то, что мы уже не можем в обном обращении к back-end запросить разнотипные объекты. А как же
ваше хвалёное GraphQL?

Проблема решается введением нового компонента, так называемого маршрутизатора. Его функция - быть фасадом вашего API. Он
как бы имитирует GraphQL сервис. У него есть схема, которая является супермножеством всех нижележащих API.

Что мы видим? У клиента упростилась жизнь, он не задумывается, куда отправлять запросы, потому что точно входа теперь
одна. И мы можем в одном запросе обращаться к разным сервисам!

Сразу хотел бы сказать пару слов о GraphQL маршрутизаторе. Это не просто какой-то обычный прокси, это специализированное
ПО. Он знает структуру GraphQL запроса и умеет производить его диспетчеризацию между всеми сервисами. А ещё, как вы
понимаете, он должен быть довольно быстрым, чтобы не замедлять работу вашего API. О маршрутизаторах я ещё скажу пару
слов в конце доклада.

Но вернёмся к нашему приложению. Как видно, API ещё далеко от идеала. Нам нужно отдельно получить список отделов и
отдельно список сотрудников. А потом надо на клиенте, на JavaScript писать логику комбинации этих двух массивов данных.
Если честно, не совсем то, что ожидалось от GraphQL. Нам бы хотелось, чтобы эти разные API имели бОльшую связность.

Ну надо, так надо. Берём сервис отделов и протягиваем связь к сервису сотрудников. Теперь сервис отделов, если его
попросят, будет вместе с информацией об отделе возвращать и список его сотрудников.

Припоминаете, что мы это уже раньше проходили, в примерах в REST? Опять увеличение связности между компонентами
приложения, усложнение самих компонентов, много рутинного кода... Нет ли какого-нибудь общего решения?

(драматическая пауза)

Да, конечно есть. Как вы догадались, надо использовать API Federation. Это известный концепт, он уже давно применяется в
том же REST API. Какие есть варианты федерации для GraphQL?

Наиболее известной является разработка компании Apollo. Я указал версию 1, потому что в настоящее время актуальной
версией является вторая, обратно несовместимая с первой. А первую я использовал в данной презентации как более простую и
наглядную. Для обеспечения федерации нам надо немного поправить наши схемы, немного доработать наши модули и, самое
главное, взять маршрутизатор, который умеет в федерацию.

Проще всего показать на примере. Итак, сперва мы доработаем схему сервиса отделов. В описание типа Department добавляем
метаданные с указанием главного ключа. Его назначание такое же, как, например, в реляционных базах данных. Главный ключ
нужен для связывания сущностей. Ключ мы определили, на этом всё! Дальше переходим к сервису сотрудников.

В схему сервиса сотрудников мы импортируем тип Department. Точнее не весь тип, а только нужные нам поля, то есть только
главный ключ. Далее мы добавляем поле со списком сотрудников. В самом сервисе нам потребуется написать резольвер,
возвращающий этот список. Всё!

Обратите внимание: мы не трогаем сервис отделов (если не считать добавления директивы @key), хотя API именно этого
сервиса подвергается изменению. Это довольно интересный эффект, иногда это может быть очень удобным. Представьте,
например, что этот сервис является тяжеленным монолитом, который уже все боятся трогать, чтобы не сломать. А
функциональность добавить хочется! И вот федерация даёт нам такую возможность.

Таким образом, федерация это не только ценный мех, это способ организовать API вашего приложения наиболее простым и
удобным образом. Собственно, этот слайд и послужил отправной точкой для названия моего доклада. GraphQL - это не только
про кодирование, оно также даёт возможности по организации вашего кода.

Пользуясь случаем, хочу поделиться парой ссылок о том, как люди использовали GraphQL федерацию для распиливания
монолитов на микросервисы. Это статья на Хабре и доклад на конференции Highload. Материалы могут быть полезными как
общим описанием технологии, так и выбором конкретных инструментов.

# Недостатки GraphQL

Теперь, наверное, пришло время бросить пару ложек дёгтя. Если вы решили взять GraphQL в свой стек, вы должны быть готовы
к некоторым проблемам.

Во-первых, GraphQL, как ни крути, добавляет сложности в проект. Появились новые возможности выстрелить в ногу.
Разработчиков, как минимум некоторых, нужно обучать. Если ваше API очень маленькое, то овчинка может не стоить выделки.
Но с другой стороны, я лично знаю приложение с огромным API, которое без GraphQL просто бы загнулось.

Также, конечно же, GraphQL добавляет оверхед при вызове вашего API. Некоторую задержку вносит сам GraphQL-фреймворк, а
каждый новый компонент, такой как маршрутизатор, добавляет латентности. Обычно это не критично, но помнить об этом
нужно.

У GraphQL есть встроенная болезнь - проблема N+1. Если писать резольверы не задумываясь, вы очень скоро с этой проблемой
столкнётесь. Поэтому обычно резольверы пишут с применением специального шаблона проектирования - DataLoader.

DataLoader ускоряет работу приложения при помощи простых пакетных операций чтения данных. Иногда ещё добавляют
кеширование, хотя и необязательно. Как правило, ваша реализация GraphQL фреймворка иметь готовые средства работы с
DataLoader. Так что это не является большой проблемой GraphQL сервисов.

А вот следующая проблема уже фундаментальная и, наверное, неустранимая. GraphQL по природе, из-за своего языка запросов,
уязвим к атакам по отказу от обслуживания. Чтобы проще это понять, вспомните как лет 20 назад программисты всего мира
боролись с проблемой SQL Injection. И по результатам той борьбы было выработано решение: никогда, никогда нельзя давать
клиенту менять запрос к базе данных. Максимум - указывать значения параметров и то со строгой валидацией. Но вот пришёл
GraphQL, и опять у клиента есть возможность писать свои собственные запросы. К чему это может привести?

Вот очень простой пример. У нас в схеме есть тип User, в котором есть рекурсивное поле.

И в один прекрасный день какой-то шутник отправил следующий запрос. В лучшем случае, сервер быстро вернёт ошибку
OutOfMemory, в худшем может просто упасть или зависнуть на долгое время.

Как с этим бороться? Сама по себе спецификация GraphQL не даёт каких-либо решений, люди выкручиваются как могут.
Например, можно ограничивать глубину вложенности запросов. Сразу скажу, это работает почти что никак. В одном из моих
прошлых проектов максимальная глубина была выставлена в значение 15! Почему так много? А просто сперва поставили
значение 10, и тут же посыпались клиенты, которым этого не хватило. Поэтому поставили 15, с запасом. Сами понимаете, от
такого ограничения толку мало, находчивому хакеру этого будет достаточно, чтобы положить сервер.

Можно ограничивать продолжительность запросов, хотя это то еще прокрустово ложе. Ведь могут быть и валидные запросы с
долгим временем работы.

Более правильным выглядит ограничивать сложность запросов. Но для этого нужна поддержка со стороны фреймворка или
какое-то внешнее решение вроде API шлюза с поддержкой GraphQL. В общем, можно много чего придумать, но это всё, к
сожалению, не добавляет business value к вашему проекту, и заказчик может не одобрить сопутствующие временные расходы.

Поэтому если ваше GraphQL API имеет доступ со стороны анонимных пользователей, и вы при этом не являетесь компанией
Netflix или Facebook, то на защиту API от хакеров может уйти весь бюджет на разработку. И даже если ваше API
непубличное, но доступное из интернета, то защита хотя бы в виде API шлюза нужна в обязательном порядке.

# Зрелость GraphQL

Напоследок, пару слов о зрелости этой технологии (на мой субъективный взгляд). При этом будем разделять саму
специцикацию - как документ - и её реализации в виде библиотек и готовых программ.

Сама по себе спецификация, конечно же, уже давно состоялась как успешный продукт, о чём говорит её использование во
многих продуктах. Но у неё есть некоторые баги или фичи, как посмотреть.

Например, в стандартном GraphQL API нет возможности по заливке файлов посредством multipart HTTP запроса. Скорее всего и
никогда не появится. Хотя некоторые независмые вендоры предлагают свои расширения на эту тему.

В языке SDL нет namespaces. И с этим приходится жить.

Есть мелкая недоработка спецификации, которая лично мне мешала жить. Я так уверенно говорю "недоработка", потому что её
уже исправили в текущем драфте новой спецификации. Осталось дождаться её релиза. И ещё пару лет подождать, пока новую
спецификацию реализуют в библиотеках.

Ещё такая проблема. В GraphQL отсутствует разделение API между пользователями. То есть, если у пользователя есть доступ
к какой-либо части API, он на самом деле имеет доступ ко всему API. Это довольно опасная ситуация. В официальной
документации рекомендуют защиту API выносить на уровень бизнес-логики. Независимые вендоры предлагают свои решения. О
каком-либо стандартном решении этой проблемы мне неизвестно.

Теперь вкратце о реализациях. Если говорить о GraphQL на уровне отдельного сервиса, но с реализациями всё хорошо,
поддерживаются все мало-мальски актуальные платформы, самих реализаций много, хотя их качество неодинаково.

Я расскажу только о том, что близко моей специализации - Java. В первую очередь это библиотека graphql-java, которая
реализует функциональность GraphQL сервера. Скорее всего вам не придётся непосредственно работать с этой библиотекой, но
она является ядром многих других фреймфорков, таких как, например...

... Spring GraphQL. Это часть всем известного фреймворка и имеет все соответствующие плюсы: достаточное качество кода,
прогнозируемая поддержка, широкое community. Наверное, большинству, кто использует Spring Boot, больше ничего никогда и
не потребуется. Но мне она показалась немного недоделанной в плане написания интеграционных тестов (хотя может я просто
не до конца разобрался). И есть некоторые незакрытые issues, вот например с транзакционностью запросов.

На всякий случай упомяну о фреймфорке от Netflix. У него есть интересные фишки, но неясно будущее этого проекта, как
долго он будет жить, как будет поддерживаться.

Из клиентов есть неплохая библиотека Apollo Kotlin, которая ранее называлась Apollo Android.

Если в вашем GraphQL сервисе потребуется поддержка федерации, то обратите внимание на библиотеку federation-jvm.

Я сам не питонист, но есть коллеги питонисты. Наслышан, что у них были проблемы с каким-то из GraphQL клиентов для
Питона. Запросы отправлялись с большой задержкой, вплоть до пары секунд. С чем это связано, не могу сказать. Возможно,
библиотека не вполне оптимально написана, а может сами коллеги неправильно её использовали. Так или иначе,
заинтересованных приглашаю ознакомиться со статьёй.

Всё упомянутое выше касалось только реализации ваших сервисов. Но напомню, что для нормального использования GraphQL в
многосервисной среде нужна федерация и её поддержка в маршрутизаторах. Вот с маршрутизаторами в мире дела обстоят не
очень. Из open-source решений мне известен только проект Apollo Route. Он является развитием проекта Apollo Server от
той же компании, но тот был написан на JavaScript и у меня, если честно, есть сомнения в его достаточной
производительности. Зато новый проект написан на Rust и обещает очень хорошую скорость. Но я никогда не использовал это
приложение, ничего не могу сказать о том, насколько стабильно и корректно оно работает. И всё, о других кандидатах на
роль маршрутизатора у меня в данный момент нет сведений. Эта ниша явно незаполнена, так что амбициозным разработчикам
есть чем заняться.

Напоследок, посмотрим, решения есть среди шлюзов API. Из того, что представлено на сайте CNCF, хотя бы какая-то
поддержка GraphQL заявлена только в проектах, отмеченных галочками. И то неясно, в каком объёме и с каким качеством эта
поддержка. Опять, как в случае с маршрутизаторами, видится явная нехватка готовых решений, при том, что GraphQL API, о
чём я выше говорил, требует особых подходов по защите от злоумышленника. Поэтому приходится пока пользоваться обычными
способами защиты, такими как квотирование обращений к API.

# Заключение

На этом я хотел бы закончить. Спасибо за внимание, в оставшееся время я готов ответить на ваши вопросы.
