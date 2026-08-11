"""核心规则与本地进度测试。运行：python -m unittest -v test_game_logic.py"""

import tempfile
import unittest
from pathlib import Path

from game import GameConfig, PlayerProgress, ProgressStore, level_config, score_guess, unlock_new_badges


class ScoreGuessTests(unittest.TestCase):
    def test_all_positions_are_correct(self) -> None:
        self.assertEqual(score_guess([0, 1, 2], [0, 1, 2]), (3, 0))

    def test_only_colors_are_correct(self) -> None:
        self.assertEqual(score_guess([0, 1, 2], [1, 2, 0]), (0, 3))

    def test_exact_and_misplaced_colors_can_coexist(self) -> None:
        self.assertEqual(score_guess([0, 1, 2, 3], [0, 2, 1, 4]), (1, 2))

    def test_repeated_colors_do_not_create_extra_hints(self) -> None:
        self.assertEqual(score_guess([0, 0, 1, 1], [0, 0, 0, 2]), (2, 0))

    def test_inconsistent_lengths_are_rejected(self) -> None:
        with self.assertRaises(ValueError):
            score_guess([0, 1], [0])


class ProgressTests(unittest.TestCase):
    def test_level_difficulty_increases_gradually(self) -> None:
        base = GameConfig(3, 4, 8)
        self.assertEqual(level_config(base, 1), GameConfig(3, 4, 8))
        self.assertEqual(level_config(base, 3), GameConfig(4, 4, 8))
        self.assertEqual(level_config(base, 4), GameConfig(4, 5, 8))

    def test_level_must_be_positive(self) -> None:
        with self.assertRaises(ValueError):
            level_config(GameConfig(3, 4, 8), 0)

    def test_badges_unlock_once(self) -> None:
        progress = PlayerProgress(total_wins=1, highest_level=5, best_timed_score=5)
        fresh = unlock_new_badges(progress, first_try=True)
        self.assertEqual(set(fresh), {"first_win", "first_try", "level_five", "timed_five"})
        self.assertEqual(unlock_new_badges(progress, first_try=True), [])

    def test_progress_survives_save_and_load(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            store = ProgressStore(Path(directory) / "progress.json")
            original = PlayerProgress(highest_level=4, best_timed_score=8, total_wins=13, unlocked_badges=["first_win"], tutorial_seen=True)
            self.assertTrue(store.save(original))
            self.assertEqual(store.load(), original)


if __name__ == "__main__":
    unittest.main()
