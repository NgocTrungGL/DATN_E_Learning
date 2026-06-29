# Cơ sở lý thuyết về cá nhân hóa học tập

## 1. Khái niệm cá nhân hóa học tập

Cá nhân hóa học tập là quá trình điều chỉnh nội dung, kế hoạch và gợi ý học tập dựa trên hành vi, tiến độ và nhu cầu riêng của từng người học. Trong một hệ thống E-learning, mỗi người dùng có thể có sở thích, tốc độ học, thời gian học và mức độ tương tác khác nhau. Vì vậy, nếu hệ thống chỉ hiển thị cùng một danh sách khóa học hoặc cùng một lộ trình học cho tất cả người dùng thì trải nghiệm học tập sẽ chưa thật sự tối ưu.

Mục tiêu của cá nhân hóa học tập là giúp người học:

- Tìm được khóa học phù hợp với sở thích và hành vi học tập.
- Có kế hoạch học tập phù hợp với thời gian và năng lực cá nhân.
- Được phát hiện sớm khi có dấu hiệu chậm tiến độ.
- Nhận được gợi ý hành động tiếp theo để tiếp tục học hiệu quả hơn.

Trong hệ thống này, nhóm chức năng cá nhân hóa học tập được triển khai theo ba hướng chính:

- Gợi ý khóa học cá nhân hóa.
- Lập kế hoạch học tập cá nhân hóa.
- Phân tích trạng thái học tập và gợi ý hành động tiếp theo.

## 2. Gợi ý khóa học cá nhân hóa

Gợi ý khóa học cá nhân hóa là chức năng đề xuất các khóa học phù hợp với từng người dùng dựa trên dữ liệu hành vi của họ trong hệ thống. Thay vì chỉ hiển thị các khóa học phổ biến giống nhau cho mọi người, hệ thống phân tích những gì người dùng đã học, đã quan tâm hoặc đã đánh giá để đưa ra danh sách khóa học có khả năng phù hợp hơn.

Các dữ liệu đầu vào được sử dụng gồm:

- Khóa học người dùng đã đăng ký.
- Khóa học người dùng đã thêm vào wishlist.
- Khóa học người dùng đã thêm vào giỏ hàng.
- Review/rating của người dùng.
- Ghi chú trong khóa học.
- Kết quả quiz đã hoàn thành.
- Danh mục của khóa học.
- Độ tương đồng giữa các khóa học.
- Mức độ phổ biến của khóa học.

Hệ thống chuyển các hành vi này thành điểm quan tâm. Những hành vi thể hiện mức độ quan tâm mạnh hơn sẽ đóng góp nhiều điểm hơn. Ví dụ, đăng ký khóa học hoặc đánh giá tốt là tín hiệu mạnh hơn so với chỉ thêm khóa học vào giỏ hàng.

Các trọng số hành vi trong hệ thống được thiết kế theo hướng heuristic, dựa trên mức độ mạnh yếu của từng tín hiệu. Những trọng số này không được xem là giá trị tối ưu tuyệt đối, mà là bộ trọng số khởi tạo có thể được kiểm chứng thông qua offline evaluation.

## 3. Content-based Filtering

Content-based Filtering là phương pháp gợi ý dựa trên nội dung hoặc đặc điểm của khóa học. Trong mô hình của đề tài, đặc trưng nội dung được dùng trực tiếp là danh mục khóa học.

Ý tưởng chính là: nếu người dùng thường tương tác với các khóa học thuộc một danh mục nhất định, hệ thống sẽ ưu tiên gợi ý thêm các khóa học trong cùng danh mục hoặc danh mục có liên quan.

Ví dụ, nếu người dùng đã học hoặc thêm vào wishlist nhiều khóa học thuộc nhóm Web Development, hệ thống có thể ưu tiên các khóa học khác cũng thuộc nhóm Web Development.

Cách tính tổng quát:

```text
CategoryAffinity = tổng điểm tương tác của user với các khóa học trong cùng danh mục
ContentScore = điểm affinity của danh mục khóa học ứng viên
```

Trong mô hình của đề tài:

- Hệ thống tính điểm quan tâm của user với từng category.
- Chỉ lấy các category có điểm dương.
- Mở rộng thêm category cha nếu có.
- Nếu khóa học thuộc category trực tiếp đã có điểm, dùng điểm đó.
- Nếu khóa học thuộc category mở rộng, dùng một phần điểm affinity cao nhất.

Công thức đơn giản:

```text
ContentScore =
  CategoryAffinity nếu khóa học thuộc category trực tiếp
  MaxCategoryAffinity * 0.5 nếu khóa học thuộc category mở rộng
```

Hệ số `0.5` được dùng để giảm độ ảnh hưởng của category mở rộng. Category trực tiếp phản ánh đúng chủ đề người dùng đã tương tác, còn category cha chỉ thể hiện quan hệ rộng hơn nên được tính điểm thấp hơn để tránh gợi ý quá xa sở thích ban đầu.

Ưu điểm của cách này là dễ hiểu, dễ giải thích và phù hợp với dữ liệu hiện có của hệ thống. Hạn chế là kết quả có thể bị giới hạn trong các chủ đề người dùng từng quan tâm.

## 4. Collaborative Filtering

Collaborative Filtering là phương pháp gợi ý dựa trên mối quan hệ giữa các khóa học. Trong hệ thống này, hướng tiếp cận được dùng là item-based collaborative filtering, tức là hệ thống không tìm người dùng giống nhau, mà tìm các khóa học giống nhau.

Ý tưởng chính là: nếu người dùng đã quan tâm đến khóa học A, và khóa học B có độ tương đồng cao với khóa học A, thì khóa học B có thể được gợi ý.

Dữ liệu đầu vào chính:

- Các khóa học user đã tương tác.
- Điểm quan tâm của user với từng khóa học.
- Bảng độ tương đồng giữa các khóa học.

Công thức chính:

```text
CollaborativeScore =
  điểm tương tác của user với khóa học nguồn
  * độ tương đồng giữa khóa học nguồn và khóa học ứng viên
```

Nếu một khóa học ứng viên tương đồng với nhiều khóa học mà user từng quan tâm, các điểm này sẽ được cộng lại.

Trong mô hình của đề tài:

- Chỉ xét các cặp khóa học có độ tương đồng lớn hơn `0.05`.
- Không gợi ý lại các khóa học user đã đăng ký.
- Điểm collaborative được chuẩn hóa theo tổng độ lớn điểm tương tác của user.

Công thức chuẩn hóa:

```text
CollaborativeScoreNorm =
  CollaborativeScore / tổng điểm tương tác tuyệt đối của user
```

Ngưỡng `0.05` giúp loại bỏ các quan hệ tương đồng quá yếu giữa hai khóa học. Nếu không có ngưỡng này, các khóa học gần như không liên quan vẫn có thể đóng góp điểm nhỏ và làm nhiễu danh sách gợi ý.

Ưu điểm của Collaborative Filtering là có thể tìm ra các khóa học liên quan dựa trên quan hệ giữa các khóa học, không chỉ dựa vào category. Hạn chế là cần dữ liệu tương tác đủ tốt để xây dựng độ tương đồng.

## 5. Popularity-based Recommendation

Popularity-based Recommendation là phương pháp gợi ý dựa trên độ phổ biến của khóa học. Phương pháp này không cá nhân hóa mạnh, nhưng rất hữu ích trong trường hợp người dùng mới hoặc người dùng có ít hành vi.

Trong mô hình của đề tài, độ phổ biến được tính dựa trên:

- Điểm rating trung bình của khóa học.
- Số lượng review.
- Số lượt đăng ký khóa học.

Để tránh trường hợp khóa học có quá ít review nhưng rating cao bất thường, hệ thống sử dụng Bayesian average rating. Ý tưởng của Bayesian average là kết hợp rating trung bình của khóa học với rating trung bình toàn hệ thống.

Công thức chính:

```text
BayesianRating =
  (C * GlobalMeanRating + ReviewCount * AverageRating)
  / (C + ReviewCount)
```

Trong đó:

- `C = 5`: số review giả định ở mức trung bình. Giá trị này đóng vai trò làm mượt, giúp một khóa học có quá ít review không bị đẩy lên quá cao chỉ vì có rating ban đầu tốt.
- `GlobalMeanRating`: rating trung bình toàn hệ thống, fallback là `3.5` nếu chưa có dữ liệu. Giá trị `3.5` được chọn như mức đánh giá trung bình khá trên thang 5 điểm.
- `ReviewCount`: số review của khóa học.
- `AverageRating`: rating trung bình của khóa học.

Sau đó điểm popularity được tính:

```text
PopularityScore =
  0.7 * BayesianRatingNorm
  + 0.3 * EnrollmentVolumeNorm
```

Trong công thức này, rating sau khi làm mượt chiếm `70%` vì chất lượng đánh giá của khóa học quan trọng hơn độ phổ biến thuần túy. Số lượt đăng ký chiếm `30%` để bổ sung tín hiệu về mức độ quan tâm của cộng đồng, nhưng không làm lấn át chất lượng rating.

Trong đó:

```text
BayesianRatingNorm = BayesianRating / 5.0
EnrollmentVolumeNorm = log10(EnrollmentCount + 1) / 5.0
```

Phép chia cho `5.0` ở `BayesianRatingNorm` dùng để đưa rating từ thang 5 điểm về khoảng gần `[0, 1]`. Với `EnrollmentVolumeNorm`, `log10(EnrollmentCount + 1)` giúp giảm ảnh hưởng của các khóa học có số lượt đăng ký quá lớn, còn phép chia cho `5.0` giúp đưa điểm enrollment về cùng thang tương đối với điểm rating. Nếu dùng trực tiếp số enrollment, các khóa học rất phổ biến có thể áp đảo toàn bộ kết quả gợi ý.

Cách tính này giúp hệ thống ưu tiên các khóa học vừa có rating tốt, vừa có lượng đăng ký tương đối ổn định.

## 6. Hybrid Recommendation

Sau khi đã có ba nguồn điểm từ Content-based Filtering, Collaborative Filtering và Popularity-based Recommendation, hệ thống sử dụng hướng tiếp cận Hybrid Recommendation để kết hợp các điểm này thành kết quả gợi ý cuối cùng.

Lý do sử dụng hybrid là vì mỗi phương pháp có ưu điểm và hạn chế riêng:

- Content-based Filtering phù hợp khi muốn gợi ý theo chủ đề người dùng quan tâm.
- Collaborative Filtering khai thác mối quan hệ giữa các khóa học.
- Popularity-based Recommendation giúp hệ thống vẫn có kết quả tốt khi người dùng có ít dữ liệu.

Điểm gợi ý cuối cùng được tính bằng cách kết hợp ba nguồn điểm:

```text
FinalScore =
  alpha * CollaborativeScore
  + beta * ContentScore
  + gamma * PopularityScore
```

Trong đó:

- `CollaborativeScore`: điểm từ phương pháp collaborative filtering.
- `ContentScore`: điểm từ phương pháp content-based filtering.
- `PopularityScore`: điểm phổ biến của khóa học.
- `alpha`, `beta`, `gamma`: trọng số quyết định mức độ ảnh hưởng của từng thành phần.

Trong phạm vi đề tài, trọng số được điều chỉnh theo lượng dữ liệu hành vi của người dùng:

| Mức dữ liệu của người dùng | alpha | beta | gamma | Ý nghĩa |
|---|---:|---:|---:|---|
| Có từ 5 khóa học tương tác trở lên | 0.50 | 0.35 | 0.15 | Ưu tiên collaborative vì đã có đủ dữ liệu |
| Có từ 2 đến 4 khóa học tương tác | 0.20 | 0.50 | 0.30 | Ưu tiên content vì dữ liệu còn vừa phải |
| Có dưới 2 khóa học tương tác | 0.00 | 0.30 | 0.70 | Ưu tiên popularity để xử lý cold-start |

Các bộ trọng số này thể hiện mức độ tin cậy của từng nguồn dữ liệu trong từng trường hợp. Khi người dùng có nhiều tương tác, dữ liệu cá nhân đã đủ để tăng vai trò của collaborative filtering. Khi người dùng có ít tương tác, hệ thống giảm vai trò collaborative và tăng vai trò content/popularity để tránh gợi ý thiếu ổn định. Tổng ba trọng số luôn bằng `1.0` để điểm cuối cùng vẫn nằm trên cùng một thang kết hợp.

Cách thiết kế này giúp hệ thống thích nghi với từng loại người dùng. Với người dùng mới, hệ thống dựa nhiều hơn vào khóa học phổ biến. Với người dùng đã có nhiều hành vi, hệ thống có thể cá nhân hóa mạnh hơn dựa trên sở thích thực tế.

## 7. AI Embedding-based Recommendation

AI Embedding-based Recommendation là phương pháp gợi ý khóa học dựa trên độ tương đồng ngữ nghĩa giữa nội dung khóa học và hồ sơ sở thích của người dùng. Khác với Content-based Filtering trong hệ thống chỉ dựa trực tiếp vào category, phương pháp embedding cố gắng biểu diễn toàn bộ nội dung mô tả khóa học thành vector số để so sánh ở mức ý nghĩa.

Embedding là cách chuyển đổi văn bản thành một vector số. Các văn bản có nội dung gần nhau sẽ có xu hướng tạo ra các vector gần nhau trong không gian embedding. Vì vậy, hai khóa học có thể được xem là liên quan nếu vector embedding của chúng gần nhau, dù chúng không nhất thiết phải trùng category.

Trong hệ thống này, AI Embedding không phải thuật toán chính thay thế toàn bộ hệ gợi ý. Nó được dùng như một phương pháp đối chứng để so sánh với thuật toán Hybrid Recommendation do hệ thống tự xây dựng. Cách thiết kế này giúp hệ thống tận dụng AI để đánh giá và so sánh, nhưng vẫn giữ phần đóng góp chính ở thuật toán recommendation được xây dựng trong đề tài.

### 7.1. Quy trình tổng quát

Quy trình AI Embedding-based Recommendation gồm năm bước:

- Xây dựng văn bản đại diện cho mỗi khóa học.
- Chuyển văn bản khóa học thành vector embedding.
- Tạo vector sở thích của người dùng từ các khóa học đã tương tác.
- So sánh vector người dùng với vector của các khóa học ứng viên.
- Sắp xếp các khóa học theo độ tương đồng và trả về danh sách gợi ý.

Luồng xử lý có thể mô tả như sau:

```text
Course content -> Course text -> Course embedding
User interactions + Course embeddings -> User preference vector
User preference vector + Candidate course embeddings -> Similarity scores
Similarity scores -> Ranked recommended courses
```

### 7.2. Xây dựng văn bản đại diện cho khóa học

Dữ liệu dùng để tạo embedding cho khóa học gồm:

- Tiêu đề khóa học.
- Danh mục khóa học.
- Mô tả khóa học.
- Learning outcomes.
- Tên module.
- Tên lesson.

Các thông tin này được ghép lại thành một đoạn văn bản đại diện cho khóa học. Mục tiêu của bước này là tạo ra một mô tả đủ giàu thông tin để mô hình embedding hiểu được khóa học đang dạy nội dung gì.

Ví dụ văn bản đại diện cho một khóa học có thể có dạng:

```text
Title: Ruby on Rails API Development
Category: Web Development
Description: Learn how to build RESTful APIs using Ruby on Rails.
Learning outcomes: Build REST APIs. Authenticate users. Connect APIs with databases.
Modules: Rails API Basics. Authentication. Database Integration.
Lessons: Routing and Controllers. JSON Responses. Token Authentication.
```

Nếu chỉ dùng tiêu đề khóa học, embedding có thể thiếu ngữ cảnh. Khi bổ sung description, learning outcomes, module và lesson title, vector embedding sẽ phản ánh nội dung học chi tiết hơn.

### 7.3. Vector hóa khóa học bằng embedding model

Sau khi hệ thống đã tạo được đoạn văn bản đại diện cho khóa học, đoạn văn bản này được đưa vào embedding model để chuyển thành vector số. Có thể hiểu embedding model như một bộ mã hóa ngữ nghĩa: nó đọc nội dung văn bản và sinh ra một dãy số đại diện cho ý nghĩa của văn bản đó.

Quá trình vector hóa khóa học có thể mô tả như sau:

```text
Course text
  -> Embedding model
  -> CourseEmbedding
  -> Lưu vào cơ sở dữ liệu
```

Ví dụ:

```text
Input cho embedding model:
Title: Ruby on Rails API Development
Category: Web Development
Description: Learn how to build RESTful APIs using Ruby on Rails.
Learning outcomes: Build REST APIs. Authenticate users. Connect APIs with databases.
Modules: Rails API Basics. Authentication. Database Integration.
Lessons: Routing and Controllers. JSON Responses. Token Authentication.
```

Output của embedding model là một vector:

```text
CourseEmbedding =
[0.021, -0.114, 0.332, 0.087, ..., 0.056]
```

Các con số trong vector không được gán thủ công. Chúng được sinh ra bởi embedding model dựa trên nội dung của khóa học. Những khóa học có nội dung gần nhau, ví dụ cùng liên quan đến Rails, API, authentication hoặc database, thường sẽ có vector gần nhau hơn so với các khóa học khác chủ đề như UI/UX hoặc Marketing.

Về mặt triển khai, embedding của khóa học nên được tạo trước và lưu lại. Khi cần gợi ý, hệ thống không cần gọi lại embedding model cho toàn bộ khóa học, mà chỉ lấy các vector đã lưu trong cơ sở dữ liệu để tính toán. Điều này giúp quá trình gợi ý nhanh hơn và giảm số lần gọi API bên ngoài.

Mỗi khóa học sau khi vector hóa sẽ có dạng:

```text
CourseEmbedding = [v1, v2, v3, ..., vn]
```

Trong đó, mỗi giá trị trong vector là một đặc trưng số học do mô hình embedding tạo ra. Người dùng không trực tiếp nhìn thấy các giá trị này, nhưng hệ thống có thể dùng chúng để tính mức độ gần nhau giữa các khóa học.

Cần phân biệt hai bước:

- Tạo `CourseEmbedding`: dùng embedding model để biến nội dung khóa học thành vector và lưu lại.
- Tính điểm gợi ý: dùng cosine similarity để so sánh `UserVector` với `CourseEmbedding` của các khóa học ứng viên.

Vì vậy, nếu hệ thống có nhiều khóa học, quá trình gợi ý không phải gọi AI cho từng khóa học ở mỗi lần user mở trang. Hệ thống chỉ so sánh các vector đã có sẵn.

Ví dụ minh họa đơn giản:

```text
Ruby on Rails API      -> [0.21, 0.62, 0.15, ...]
Backend Security       -> [0.18, 0.58, 0.22, ...]
UI/UX Design Basics    -> [0.73, 0.11, 0.05, ...]
```

Trong ví dụ trên, `Ruby on Rails API` và `Backend Security` có thể gần nhau hơn vì cùng liên quan đến backend/API, còn `UI/UX Design Basics` khác hướng nội dung hơn.

### 7.4. Tạo vector sở thích của người dùng

Sau khi mỗi khóa học đã có embedding, hệ thống cần tạo một vector đại diện cho sở thích của người dùng. Vector này được xây dựng từ các khóa học mà user đã tương tác trước đó.

Không phải tương tác nào cũng có mức độ quan trọng như nhau. Ví dụ, một khóa học đã đăng ký hoặc đánh giá 5 sao thể hiện mức quan tâm mạnh hơn một khóa học chỉ mới nằm trong cart. Vì vậy, hệ thống sử dụng trung bình có trọng số để tạo vector hồ sơ.

Công thức chính:

```text
UserVector =
  tổng(điểm tương tác * CourseEmbedding)
  / tổng(điểm tương tác)
```

Các tín hiệu được dùng để xây dựng hồ sơ AI embedding gồm:

| Tín hiệu | Điểm |
|---|---:|
| Active enrollment | 4.0 |
| Pending enrollment | 2.0 |
| Review 5 sao | 5.0 |
| Review 4 sao | 3.0 |
| Wishlist | 3.0 |
| Cart | 2.0 |

Các điểm trong bảng thể hiện mức độ mạnh/yếu của tín hiệu khi xây dựng vector sở thích. Review 5 sao và active enrollment được xem là tín hiệu mạnh, wishlist và cart là tín hiệu quan tâm trung bình, còn pending enrollment thấp hơn vì chưa chắc người dùng đã thật sự học khóa đó. Các giá trị này là trọng số khởi tạo để tạo hồ sơ embedding, không được xem là hằng số tối ưu tuyệt đối.

Ví dụ, nếu user đã tương tác với ba khóa học:

```text
Ruby on Rails Basic       điểm tương tác 4.0
REST API Development      điểm tương tác 3.0
Database Design           điểm tương tác 2.0
```

thì vector sở thích của user sẽ nghiêng nhiều hơn về `Ruby on Rails Basic`, vì khóa học này có điểm tương tác cao nhất. Cách tính này giúp hồ sơ người dùng phản ánh cả nội dung khóa học lẫn mức độ quan tâm của user đối với từng khóa học.

### 7.5. Tính độ tương đồng với khóa học ứng viên

Sau khi có vector hồ sơ người dùng, hệ thống so sánh vector này với vector của các khóa học ứng viên bằng cosine similarity:

```text
CosineSimilarity =
  (A . B) / (||A|| * ||B||)
```

Trong đó:

- `A`: vector hồ sơ người dùng.
- `B`: vector khóa học ứng viên.
- Giá trị càng cao thì khóa học càng gần với sở thích của người dùng về mặt ngữ nghĩa.

Cosine similarity phù hợp trong bài toán này vì hệ thống cần so sánh hướng của hai vector hơn là độ lớn tuyệt đối của vector. Nếu hai vector có hướng gần nhau, điều đó cho thấy nội dung khóa học ứng viên gần với sở thích đã học của user.

Các khóa học đã được user tương tác trước đó sẽ bị loại khỏi danh sách ứng viên để tránh gợi ý lại nội dung cũ. Kết quả cuối cùng là danh sách khóa học có cosine similarity cao nhất.

### 7.6. Ví dụ đầu vào và đầu ra

Ví dụ đầu vào:

```text
Input:
User đã tương tác với:
- Ruby on Rails Basic, điểm tương tác 4.0
- REST API Development, điểm tương tác 3.0
- Database Design, điểm tương tác 2.0

Khóa học ứng viên:
- Advanced Rails API
- UI/UX Design Fundamentals
- PostgreSQL Performance
```

Hệ thống sẽ tạo vector sở thích của user từ ba khóa học đã tương tác. Sau đó, vector này được so sánh với vector của từng khóa học ứng viên:

```text
Output:
Advanced Rails API           cosine similarity = 0.91
PostgreSQL Performance       cosine similarity = 0.82
UI/UX Design Fundamentals    cosine similarity = 0.43
```

Trong ví dụ trên, `Advanced Rails API` được xếp cao nhất vì nội dung gần với các khóa học mà user đã quan tâm như Ruby on Rails và REST API. `PostgreSQL Performance` vẫn có liên quan do user từng quan tâm đến Database Design. `UI/UX Design Fundamentals` có điểm thấp hơn vì khác hướng nội dung so với hồ sơ học tập hiện tại của user.

### 7.7. Vai trò trong đánh giá thuật toán

Trong phạm vi đề tài, AI Embedding-based Recommendation được dùng như một phương pháp so sánh với Hybrid Recommendation. Hai phương pháp có cách tiếp cận khác nhau:

- Hybrid Recommendation khai thác hành vi, category, course similarity và popularity.
- AI Embedding-based Recommendation khai thác sự gần nhau về mặt ngữ nghĩa giữa nội dung khóa học và hồ sơ sở thích của user.

Khi đánh giá offline, hệ thống có thể so sánh danh sách gợi ý của hai phương pháp bằng các chỉ số như Precision, Recall, NDCG và Overlap. Nếu Hybrid Recommendation đạt kết quả tốt hơn hoặc tương đương AI Embedding, điều đó cho thấy thuật toán tự xây dựng có cơ sở hoạt động tốt trên dữ liệu của hệ thống. Nếu AI Embedding tạo ra kết quả khác biệt, nó có thể được xem như một góc nhìn bổ sung dựa trên ngữ nghĩa nội dung.

Ưu điểm của AI Embedding-based Recommendation là có thể phát hiện quan hệ ngữ nghĩa giữa các khóa học ngay cả khi chúng không nằm cùng category trực tiếp. Ví dụ, một khóa học về API Authentication và một khóa học về Backend Security có thể liên quan về mặt nội dung dù không nhất thiết cùng một danh mục nhỏ.

Tuy nhiên, phương pháp này cũng có hạn chế. Chất lượng gợi ý phụ thuộc vào chất lượng nội dung văn bản của khóa học và chất lượng embedding được tạo ra. Ngoài ra, nếu sử dụng API bên ngoài, hệ thống còn phụ thuộc vào chi phí, giới hạn request và khả năng cập nhật embedding khi nội dung khóa học thay đổi.

## 8. Cá nhân hóa kế hoạch học tập

Ngoài gợi ý khóa học, hệ thống còn hỗ trợ cá nhân hóa kế hoạch học tập cho từng người dùng. Mục tiêu của chức năng này là phân bổ các lesson trong khóa học thành lịch học phù hợp với tốc độ học, thời gian học và deadline của người học.

Điểm quan trọng là hệ thống không tự ý đảo thứ tự lesson. Thứ tự lesson vẫn được giữ theo thiết kế của người tạo khóa học, vì trong một khóa học thông thường, instructor đã sắp xếp nội dung từ cơ bản đến nâng cao. Cá nhân hóa ở đây nằm ở cách chia lịch, khối lượng học mỗi ngày và deadline phù hợp với từng người học.

Dữ liệu đầu vào chính gồm:

- Danh sách lesson của khóa học.
- Thứ tự lesson trong module/course.
- Thời lượng ước tính của lesson.
- Lịch sử học tập 30 ngày gần nhất của user.
- Deadline mong muốn.
- Ngày hoặc khung giờ học ưu tiên.

Từ dữ liệu lịch sử, hệ thống ước lượng learning profile của user, gồm tốc độ học trung bình, số giờ học trung bình mỗi ngày, các ngày thường học và thời lượng trung bình cho mỗi lesson. Thông tin này được dùng để tính sức học mỗi ngày:

```text
DailyCapacity =
  thời gian học trung bình mỗi ngày của user
```

Khi tạo plan, hệ thống xếp lesson theo thứ tự course/module và phân bổ vào các ngày học sao cho tổng thời lượng trong ngày không vượt quá daily capacity.

Để kiểm tra kế hoạch có khả thi hay không, hệ thống so sánh khối lượng học cần hoàn thành mỗi ngày với sức học ước tính:

```text
RequiredPerDay = RemainingMinutes / RemainingDays
```

Nếu `RequiredPerDay` quá cao so với `DailyCapacity`, kế hoạch được xem là quá tải và hệ thống có thể đề xuất điều chỉnh deadline. Nhờ đó, kế hoạch học không chỉ dựa trên số lượng lesson, mà còn xét đến khả năng học thực tế của từng user.

Tóm lại, phần cá nhân hóa kế hoạch học tập không phải là thay đổi nội dung khóa học, mà là điều chỉnh lịch học để phù hợp hơn với thói quen và năng lực học của từng người.

## 9. Phân tích trạng thái và rủi ro học tập

Sau khi người dùng có study plan, hệ thống tiếp tục phân tích quá trình học để phát hiện các dấu hiệu chậm tiến độ hoặc có nguy cơ bỏ dở.

Dữ liệu đầu vào gồm:

- Learning activities trong 30 ngày gần nhất.
- Progress tracking của lesson.
- Study plan items.
- Trạng thái overdue, skipped, in progress.
- Thời điểm hoạt động gần nhất.
- Khối lượng học còn lại.
- Daily capacity của người học.

Hệ thống tạo behavior profile gồm:

- Số ngày có hoạt động học.
- Tổng số phút học.
- Số lesson đã xem.
- Số lesson đã hoàn thành.
- Phần trăm tiến độ khóa học.
- Phần trăm tiến độ study plan.
- Số item pending, overdue, skipped, in progress.
- Số ngày không hoạt động.
- Số phút học còn lại.
- Số phút cần học mỗi ngày để kịp deadline.

Điểm rủi ro được tính từ nhiều nhóm tín hiệu:

```text
RiskScore =
  InactivityScore
  + OverdueScore
  + SkippedScore
  + UnfinishedScore
  + WorkloadScore
```

Các nhóm tín hiệu chính:

- Không có hoạt động học trong nhiều ngày.
- Có nhiều study plan item bị overdue.
- Có lesson bị skipped.
- Có lesson đang học dở.
- Khối lượng học còn lại vượt quá năng lực học ước tính.

Ngưỡng phân loại trạng thái:

| Risk score | Trạng thái |
|---:|---|
| 0 - 9 | On track |
| 10 - 24 | Needs attention |
| 25 - 49 | Behind |
| 50 - 100 | At risk |

Kết quả trả về gồm:

- Mức rủi ro.
- Điểm rủi ro.
- Lý do dẫn đến rủi ro.
- Gợi ý tổng quát cho người học.

Ví dụ:

```text
Risk level: At risk
Reason:
- No activity in 7 days
- 3 study plan items are overdue
- Remaining workload is above current study pace
```

Cách tiếp cận này là rule-based, dễ giải thích và phù hợp với dữ liệu mà hệ thống đang thu thập.

Các ngưỡng risk score được chia theo mức độ nghiêm trọng tăng dần. `On track` là trạng thái bình thường, `Needs attention` thể hiện có tín hiệu cần chú ý, `Behind` cho thấy người học đã chậm tiến độ, và `At risk` là trường hợp cần ưu tiên can thiệp bằng hành động học bù hoặc điều chỉnh kế hoạch.

## 10. Gợi ý hành động học tập tiếp theo

Sau khi phân tích trạng thái học tập, hệ thống không chỉ hiển thị cảnh báo mà còn đề xuất hành động cụ thể để người học biết nên làm gì tiếp theo.

Các loại hành động đang được hỗ trợ:

| Hành động | Ý nghĩa | Độ ưu tiên |
|---|---|---:|
| Resume | Tiếp tục lesson đang học dở | 100 |
| Catch up | Học bù lesson quá hạn | 90 |
| Revisit | Xem lại lesson đã bỏ qua | 70 |
| Start | Bắt đầu lesson được lên lịch hôm nay | 60 |
| Continue | Học lesson tiếp theo theo thứ tự course | 40 |

Danh sách hành động được sắp xếp theo độ ưu tiên. Nếu có nhiều hành động cùng loại, hệ thống ưu tiên các item có lịch học sớm hơn.

Các điểm ưu tiên được thiết kế theo mức độ khẩn cấp của hành động. Lesson đang học dở được ưu tiên cao nhất để giúp người học tiếp tục mạch học. Lesson quá hạn đứng sau vì ảnh hưởng trực tiếp đến tiến độ. Lesson đã bỏ qua được xếp thấp hơn overdue nhưng vẫn cao hơn lesson mới. Lesson hôm nay và lesson tiếp theo có độ ưu tiên thấp hơn vì chưa tạo ra rủi ro lớn.

Ý nghĩa của chức năng này là giúp người học giảm sự phân vân khi quay lại hệ thống. Thay vì phải tự tìm xem nên học gì tiếp, user nhận được danh sách hành động rõ ràng dựa trên trạng thái học tập của mình.

## 11. Offline Evaluation cho hệ gợi ý

Do hệ thống chưa có nhiều người dùng thật để triển khai A/B Testing, hệ thống sử dụng Offline Evaluation để đánh giá thuật toán gợi ý. Đây là phương pháp đánh giá dựa trên dữ liệu lịch sử đã có.

Ý tưởng chính là dùng một phần lịch sử học tập cũ của user để tạo hồ sơ, sau đó kiểm tra xem thuật toán có gợi ý đúng các khóa học mà user đã học sau đó hay không.

Trong phạm vi đánh giá của đề tài:

- Chỉ đánh giá trên student có ít nhất 5 active enrollments.
- Các enrollment được sắp xếp theo thời gian.
- Một số enrollment gần nhất được giữ lại làm ground truth.
- Các tương tác trước đó được dùng để tạo profile.
- So sánh kết quả của Hybrid Recommendation và AI Embedding Recommendation.

Ground truth được lấy từ các enrollment gần nhất:

```text
GroundTruth =
  last min(2, ceil(25% * active_enrollments_count)) active enrollments
```

Điều kiện `ít nhất 5 active enrollments` giúp đảm bảo mỗi user có đủ lịch sử để tách dữ liệu thành phần huấn luyện và phần kiểm tra. Nếu user có quá ít khóa học, kết quả đánh giá sẽ kém ổn định. Phần ground truth lấy tối đa 2 enrollment gần nhất hoặc khoảng 25% số enrollment để mô phỏng tình huống dự đoán các khóa học người dùng quan tâm về sau, đồng thời vẫn giữ lại đủ dữ liệu cũ để xây dựng hồ sơ người dùng.

Các chỉ số đánh giá chính:

### Precision@K

Precision@K đo tỷ lệ kết quả gợi ý trong top K là đúng.

```text
Precision@K =
  số khóa học gợi ý đúng / K
```

Precision cao cho thấy danh sách gợi ý ít bị nhiễu.

### Recall@K

Recall@K đo tỷ lệ khóa học đúng được tìm thấy trong top K.

```text
Recall@K =
  số khóa học gợi ý đúng / tổng số khóa học đúng trong ground truth
```

Recall cao cho thấy thuật toán tìm lại được nhiều khóa học mà người dùng thật sự quan tâm.

### NDCG@K

NDCG@K đánh giá chất lượng thứ hạng của danh sách gợi ý. Nếu khóa học đúng xuất hiện ở vị trí càng cao, điểm NDCG càng tốt.

Công thức chính:

```text
NDCG@K = DCG@K / IDCG@K
```

Trong đó:

- `DCG@K`: điểm thứ hạng thực tế của danh sách gợi ý.
- `IDCG@K`: điểm thứ hạng lý tưởng nếu tất cả kết quả đúng nằm ở đầu danh sách.

### Overlap

Overlap dùng để so sánh mức độ giống nhau giữa hai thuật toán gợi ý, cụ thể là Hybrid Recommendation và AI Embedding Recommendation.

Trong phạm vi đề tài, overlap được tính theo Jaccard similarity:

```text
Overlap =
  số khóa học trùng nhau giữa hai danh sách
  / tổng số khóa học khác nhau trong hai danh sách
```

Nếu overlap cao, hai thuật toán có xu hướng đưa ra kết quả giống nhau. Nếu overlap thấp, hai thuật toán đang khai thác các góc nhìn khác nhau.

Ngoài đánh giá exact match, hệ thống còn có soft relevance. Một khóa học được xem là liên quan mềm nếu:

- Trùng trực tiếp với ground truth.
- Thuộc category liên quan.
- Có semantic similarity với ground truth đạt ngưỡng `0.80`.

Ngưỡng semantic similarity `0.80` được dùng để chỉ xem các khóa học có mức tương đồng ngữ nghĩa cao là liên quan mềm. Nếu đặt ngưỡng quá thấp, nhiều khóa học chỉ hơi giống nhau cũng có thể được tính là liên quan, làm kết quả đánh giá dễ bị lạc quan.

Việc dùng offline evaluation giúp hệ thống có cơ sở định lượng để so sánh thuật toán mà không cần lượng lớn người dùng thật trong giai đoạn demo đồ án.

## 12. Tổng kết

Nhóm chức năng cá nhân hóa học tập trong hệ thống không chỉ dừng lại ở việc gợi ý khóa học, mà còn hỗ trợ người học trong quá trình học sau khi đã đăng ký khóa học.

Các thành phần chính gồm:

- Hybrid Recommendation để gợi ý khóa học phù hợp.
- AI Embedding Recommendation để làm phương pháp đối chứng.
- Study Plan Personalization để tạo kế hoạch học phù hợp với từng user.
- Learning Risk Detection để phát hiện trạng thái chậm tiến độ.
- Focus Recommendation để đề xuất hành động học tập tiếp theo.
- Offline Evaluation để đánh giá thuật toán gợi ý bằng dữ liệu lịch sử.

Điểm mạnh của hướng tiếp cận này là hệ thống không phụ thuộc hoàn toàn vào AI API. Thuật toán chính được xây dựng dựa trên dữ liệu và rule trong hệ thống, còn AI Embedding được dùng để so sánh và hỗ trợ đánh giá. Điều này giúp chức năng cá nhân hóa vừa có tính ứng dụng thực tế, vừa có cơ sở kỹ thuật phù hợp với phạm vi đồ án tốt nghiệp.

## 13. Tài liệu tham khảo đề xuất

1. Hu, Y., Koren, Y., & Volinsky, C. (2008). Collaborative Filtering for Implicit Feedback Datasets. ICDM.
2. Rendle, S., Freudenthaler, C., Gantner, Z., & Schmidt-Thieme, L. (2009). BPR: Bayesian Personalized Ranking from Implicit Feedback. UAI.
3. Cano, E., & Morisio, M. (2019). Hybrid Recommender Systems: A Systematic Literature Review.
4. Jarvelin, K., & Kekalainen, J. (2002). Cumulated gain-based evaluation of IR techniques. ACM Transactions on Information Systems.
