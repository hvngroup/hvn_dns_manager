---
description: Kiểm tra tiến độ dự án
---

# Check Project Status

Tổng kết tiến độ dự án.

## Steps

1. **Scan workspace**: liệt kê files đã tạo trong `app/`, `templates/`, `tests/`

2. **Map với EPICS.md**:
   - Đối chiếu files → Issues
   - Đánh dấu: ✅ Done, 🔨 In Progress, ⬜ Not Started

3. **Output bảng tiến độ**:

Phase 1 MVP:
EPIC-01 Foundation:     ████████░░ 80% (4/5 stories)
EPIC-02 Queue & Cron:   ██████░░░░ 60% (2/3 stories)
EPIC-03 DNS Editor:     ████░░░░░░ 40% (1/3 stories)
...

4. **Liệt kê blockers** nếu có dependencies chưa hoàn thành

5. **Đề xuất** issue tiếp theo nên implement