# Kết quả đánh giá hệ thống gợi ý khóa học

## 1. Mục tiêu đánh giá

Phần này trình bày kết quả so sánh giữa hai phương pháp gợi ý khóa học:

- **Hybrid Recommendation**: thuật toán chính của hệ thống.
- **AI Embedding-based Recommendation**: phương pháp đối chứng dùng để so sánh.

Mục tiêu là đánh giá chất lượng gợi ý của thuật toán chính bằng các chỉ số định lượng, đồng thời so sánh với phương pháp đối chứng dựa trên AI Embedding.

## 2. Thiết lập đánh giá

Hệ thống sử dụng Offline Evaluation trên dữ liệu lịch sử để đánh giá khả năng dự đoán khóa học người dùng quan tâm tiếp theo.

Thiết lập đánh giá:

- Chỉ chọn student có ít nhất 5 active enrollments.
- Các enrollment được sắp xếp theo thời gian.
- Một số enrollment gần nhất được giữ lại làm ground truth.
- Các tương tác trước đó được dùng để xây dựng hồ sơ người dùng.
- Mỗi thuật toán trả về top 5 khóa học gợi ý.

### 2.1. Cách xây dựng tập ground truth

Ground truth là tập khóa học được dùng làm đáp án thực tế để kiểm tra kết quả gợi ý. Trong đánh giá này, ground truth được lấy từ các khóa học mà user thật sự đăng ký ở giai đoạn sau của lịch sử học tập.

Quy trình xây dựng ground truth:

1. Lấy các active enrollments của từng user.
2. Sắp xếp enrollment theo thời gian đăng ký.
3. Giữ lại một số enrollment gần nhất làm ground truth.
4. Các tương tác xảy ra trước ground truth được dùng để tạo hồ sơ người dùng.

Cách lấy ground truth:

```text
GroundTruth =
  last min(2, ceil(25% * active_enrollments_count)) active enrollments
```

Ví dụ:

```text
User có 6 active enrollments theo thứ tự thời gian:
C1, C2, C3, C4, C5, C6

Profile input:
C1, C2, C3, C4

Ground truth:
C5, C6
```

Trong ví dụ trên, thuật toán chỉ được sử dụng dữ liệu từ `C1-C4` để tạo gợi ý. Nếu danh sách top 5 gợi ý có chứa `C5` hoặc `C6`, kết quả đó được tính là đúng theo exact relevance.

Cách chia này giúp đánh giá khả năng dự đoán khóa học tiếp theo dựa trên lịch sử học trước đó của user.

Lệnh xuất kết quả đánh giá:

```bash
bundle exec rails runner 'result = Recommendations::OfflineEvaluator.new(k: 5, user_limit: 200).call; puts JSON.pretty_generate({evaluated_users: result[:evaluated_users], k: result[:k], embedded_courses: result[:embedded_courses], published_courses: result[:published_courses], hybrid: result[:hybrid], ai_embedding: result[:ai_embedding], overlap: result[:overlap]})'
```

## 3. Thống kê dữ liệu đánh giá

| Chỉ số | Giá trị |
|---|---:|
| Số user được đánh giá | `200` |
| Số kết quả gợi ý mỗi user | `5` |
| Số khóa học published | `478` |
| Số khóa học có embedding | `478` |

Tập đánh giá gồm 200 người học và 478 khóa học đang ở trạng thái published. Toàn bộ 478 khóa học đều có embedding, vì vậy phương pháp AI Embedding có thể tham gia đánh giá trên toàn bộ tập khóa học published.

## 4. Ngưỡng diễn giải kết quả

Để việc đọc kết quả rõ ràng hơn, đề tài sử dụng các ngưỡng diễn giải theo từng nhóm chỉ số. Các ngưỡng này không phải là chuẩn tuyệt đối cho mọi hệ thống gợi ý, mà được dùng như thang đánh giá trong phạm vi thực nghiệm của đề tài.

### 4.1. Ngưỡng cho Hit Rate, Recall và NDCG

| Giá trị | Mức đánh giá | Ý nghĩa |
|---:|---|---|
| `< 0.05` | Thấp | Thuật toán rất ít khi tìm được khóa học đúng hoặc xếp hạng đúng chưa tốt |
| `0.05 - 0.15` | Trung bình thấp | Thuật toán bắt đầu có khả năng dự đoán nhưng độ chính xác còn hạn chế |
| `0.15 - 0.30` | Trung bình | Thuật toán có tín hiệu gợi ý rõ hơn trên tập đánh giá |
| `> 0.30` | Tốt | Thuật toán tìm được nhiều kết quả liên quan trong top K |

### 4.2. Ngưỡng cho Precision@5

Precision@5 thường có giá trị thấp hơn Hit Rate vì chỉ có tối đa một vài khóa học trong ground truth, trong khi danh sách gợi ý có 5 khóa học.

| Giá trị | Mức đánh giá | Ý nghĩa |
|---:|---|---|
| `< 0.01` | Thấp | Gần như không có kết quả đúng trong top 5 |
| `0.01 - 0.03` | Trung bình thấp | Có xuất hiện kết quả đúng nhưng tỷ lệ còn thấp |
| `0.03 - 0.06` | Trung bình | Danh sách top 5 bắt đầu có kết quả đúng đáng ghi nhận |
| `> 0.06` | Tốt | Tỷ lệ kết quả đúng trong top 5 tương đối tốt |

### 4.3. Ngưỡng cho Soft Precision và Soft Recall

Soft relevance đánh giá các khóa học liên quan gần đúng, vì vậy thang đánh giá cao hơn exact relevance.

| Giá trị | Mức đánh giá | Ý nghĩa |
|---:|---|---|
| `< 0.20` | Thấp | Ít khóa học được gợi ý có liên quan về nội dung |
| `0.20 - 0.40` | Trung bình | Có khả năng gợi ý một phần khóa học liên quan |
| `0.40 - 0.60` | Khá | Nhiều khóa học trong top 5 có liên quan gần đúng |
| `> 0.60` | Tốt | Danh sách gợi ý có mức liên quan nội dung cao |

### 4.4. Ngưỡng cho Overlap

Overlap không dùng để đánh giá tốt/xấu trực tiếp, mà dùng để xem hai thuật toán giống hay khác nhau.

| Giá trị | Mức trùng lặp | Ý nghĩa |
|---:|---|---|
| `< 0.10` | Thấp | Hai thuật toán tạo danh sách gợi ý khác nhau rõ rệt |
| `0.10 - 0.30` | Trung bình | Hai thuật toán có một phần kết quả giống nhau |
| `> 0.30` | Cao | Hai thuật toán có xu hướng gợi ý tương tự nhau |

## 5. Kết quả exact relevance

Exact relevance chỉ tính là đúng khi khóa học được gợi ý trùng trực tiếp với khóa học trong ground truth.

| Thuật toán | Hit Rate@5 | Precision@5 | Recall@5 | NDCG@5 |
|---|---:|---:|---:|---:|
| Hybrid Recommendation | `0.115` | `0.036` | `0.090` | `0.081` |
| AI Embedding | `0.015` | `0.003` | `0.008` | `0.004` |

Nhận xét kết quả:

- `Hit Rate@5` cho biết thuật toán có gợi ý trúng ít nhất một khóa học trong ground truth hay không.
- `Precision@5` cho biết trong 5 khóa học được gợi ý có bao nhiêu khóa học đúng.
- `Recall@5` cho biết thuật toán tìm lại được bao nhiêu phần trong ground truth.
- `NDCG@5` phản ánh chất lượng thứ hạng, khóa học đúng xuất hiện càng cao thì điểm càng tốt.

Kết quả exact relevance cho thấy Hybrid Recommendation vượt AI Embedding ở toàn bộ các chỉ số exact. Hybrid đạt `0.115` ở Hit Rate@5, cao hơn AI Embedding (`0.015`). Precision@5 của Hybrid là `0.036`, trong khi AI Embedding đạt `0.003`. NDCG@5 của Hybrid cũng cao hơn đáng kể (`0.081` so với `0.004`), cho thấy Hybrid có khả năng đưa khóa học trùng ground truth lên vị trí tốt hơn trong danh sách gợi ý.

Điều này cho thấy thuật toán Hybrid phản ánh tốt hơn hành vi đăng ký khóa học thực tế trong dữ liệu đánh giá. Nguyên nhân hợp lý là Hybrid Recommendation tận dụng trực tiếp các tín hiệu hành vi, category, course similarity và popularity, trong khi AI Embedding chủ yếu dựa vào mức độ gần nhau về mặt nội dung.

Đối chiếu với ngưỡng đánh giá, Hybrid Recommendation đạt mức **trung bình thấp** ở Hit Rate@5, Recall@5 và NDCG@5, đồng thời đạt mức **trung bình** ở Precision@5. AI Embedding nằm ở mức **thấp** trên nhóm exact metrics. Kết quả này cho thấy Hybrid Recommendation phù hợp hơn cho mục tiêu dự đoán chính xác khóa học người dùng đăng ký tiếp theo.

## 6. Kết quả soft relevance

Soft relevance tính cả các khóa học có liên quan gần đúng, ví dụ cùng category liên quan hoặc gần nhau về mặt semantic.

| Thuật toán | Soft Hit Rate@5 | Soft Precision@5 | Soft Recall@5 | Soft NDCG@5 | Avg Semantic |
|---|---:|---:|---:|---:|---:|
| Hybrid Recommendation | `0.705` | `0.329` | `0.613` | `0.554` | `0.792` |
| AI Embedding | `0.775` | `0.578` | `0.730` | `0.673` | `0.811` |

Nhận xét kết quả:

- Soft relevance phản ánh khả năng gợi ý các khóa học liên quan gần đúng về category hoặc ngữ nghĩa.
- Trong bối cảnh E-learning, chỉ số này có ý nghĩa vì nhiều khóa học khác nhau vẫn có thể phục vụ cùng một mục tiêu học tập.
- `Avg Semantic` cho biết trung bình mức độ gần nhau về mặt nội dung giữa kết quả gợi ý và ground truth.

Kết quả soft relevance cho thấy AI Embedding đạt điểm cao hơn Hybrid Recommendation ở tất cả các chỉ số liên quan mềm. AI Embedding đạt Soft Hit Rate@5 là `0.775`, cao hơn Hybrid (`0.705`). Soft Precision@5 của AI Embedding là `0.578`, cao hơn đáng kể so với Hybrid (`0.329`). Soft NDCG@5 của AI Embedding cũng cao hơn (`0.673` so với `0.554`).

Kết quả này phù hợp với bản chất của AI Embedding: phương pháp này không nhất thiết dự đoán trùng chính xác khóa học user học sau đó, nhưng có khả năng tìm ra các khóa học gần về mặt nội dung hoặc ngữ nghĩa. Avg Semantic của AI Embedding đạt `0.811`, cao hơn Hybrid (`0.792`), cho thấy các khóa học do AI Embedding gợi ý có mức gần nội dung với ground truth tốt hơn.

Đối chiếu với ngưỡng đánh giá, Hybrid Recommendation đạt mức **trung bình** ở Soft Precision@5 và mức **tốt** ở Soft Recall@5. AI Embedding đạt mức **khá** ở Soft Precision@5 và mức **tốt** ở Soft Recall@5. Điều này cho thấy AI Embedding nổi bật hơn ở khả năng gợi ý các khóa học liên quan gần đúng về nội dung.

## 7. Mức độ trùng lặp giữa hai phương pháp

| Chỉ số | Giá trị |
|---|---:|
| Overlap@5 | `0.046` |

Nhận xét:

- Overlap cao cho thấy hai phương pháp có xu hướng tạo ra danh sách gợi ý giống nhau.
- Overlap thấp cho thấy hai phương pháp khai thác các góc nhìn khác nhau.
- Hybrid Recommendation dựa nhiều hơn vào hành vi và cấu trúc dữ liệu hệ thống.
- AI Embedding dựa nhiều hơn vào ý nghĩa nội dung khóa học.

Overlap@5 đạt `0.046`, cho thấy hai phương pháp tạo ra danh sách gợi ý khá khác biệt. Điều này phản ánh sự khác nhau trong nguồn tín hiệu: Hybrid Recommendation khai thác hành vi và cấu trúc dữ liệu trong hệ thống, còn AI Embedding khai thác độ gần nhau về mặt ngữ nghĩa của nội dung khóa học.

Theo ngưỡng diễn giải, Overlap@5 nằm ở mức **thấp**. Điều này cho thấy AI Embedding không chỉ lặp lại danh sách gợi ý của Hybrid Recommendation, mà tạo ra một góc nhìn khác dựa trên semantic similarity.

## 8. Nhận xét tổng hợp

Từ các bảng kết quả, có thể tổng hợp đánh giá theo ba nhóm chỉ số:

1. Ở exact metrics, Hybrid Recommendation cho kết quả tốt hơn AI Embedding. Điều này cho thấy thuật toán Hybrid phù hợp hơn với mục tiêu dự đoán chính xác khóa học mà user đăng ký trong giai đoạn tiếp theo.

2. Ở soft metrics, AI Embedding cho kết quả tốt hơn. Điều này cho thấy AI Embedding có lợi thế trong việc tìm các khóa học gần về nội dung, category hoặc ngữ nghĩa, ngay cả khi không trùng chính xác ground truth.

3. Overlap@5 thấp cho thấy hai phương pháp không tạo ra danh sách gợi ý giống nhau. Vì vậy, AI Embedding không chỉ lặp lại kết quả của Hybrid Recommendation, mà cung cấp một góc nhìn khác dựa trên semantic similarity.

## 9. Kết luận đánh giá

Kết quả đánh giá cho thấy hệ thống gợi ý được kiểm tra bằng các chỉ số định lượng thay vì chỉ dựa trên quan sát giao diện.

Hybrid Recommendation là thuật toán chính vì tận dụng được nhiều tín hiệu trong hệ thống như hành vi người dùng, category, course similarity và popularity. AI Embedding đóng vai trò phương pháp đối chứng, giúp kiểm tra thêm khả năng gợi ý dựa trên ngữ nghĩa nội dung khóa học.

Từ kết quả thực nghiệm, Hybrid Recommendation phù hợp hơn với bài toán dự đoán chính xác khóa học user sẽ đăng ký tiếp theo, thể hiện qua các chỉ số exact cao hơn AI Embedding. Ngược lại, AI Embedding thể hiện ưu thế ở nhóm chỉ số soft relevance, cho thấy khả năng tìm các khóa học liên quan về mặt nội dung tốt hơn.

Do đó, hai phương pháp có vai trò khác nhau trong hệ thống đánh giá. Hybrid Recommendation là thuật toán chính phù hợp với dữ liệu hành vi của hệ thống, còn AI Embedding là phương pháp đối chứng có giá trị trong việc đánh giá khía cạnh ngữ nghĩa của nội dung khóa học. Kết quả này cũng cho thấy hướng phát triển tiềm năng là kết hợp thêm tín hiệu semantic từ embedding vào Hybrid Recommendation để tận dụng ưu điểm của cả hai phương pháp.
