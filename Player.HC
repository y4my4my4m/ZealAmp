#define IMG_MAIN player.images[0]
#define IMG_CBUTTONS player.images[1]
#define IMG_TEXT player.images[2]
#define IMG_NUMBERS player.images[3]
#define IMG_PLAYPAUS player.images[4]

#define BTN_NULL 0
#define BTN_PREV 1
#define BTN_PLAY 2
#define BTN_PAUSE 3
#define BTN_STOP 4
#define BTN_NEXT 5
#define BTN_EJECT 6

#define ACTION_NULL 0
#define ACTION_PICK_FILE 1

#define SRC_TYPE_NULL 0
#define SRC_TYPE_PCM 1
#define SRC_TYPE_MP3 2

class @drmp3_config {
  U32 channels;
  U32 sampleRate;
};

class @id3v1 {
  U8 header[3];
  U8 title[30];
  U8 artist[30];
  U8 album[30];
  U8 year[4];
};

class @media : @id3v1 {
  U32 channels;
  U32 sampleRate;
  U8 *source_data;
  I64 source_len;
  I64 source_type;
  U8 *pcm_data;
  I64 pcm_frames;
  I64 runtime_mins;
  I64 runtime_secs;
  Bool paused;
  Bool stopped;
};

class @marquee_char {
  @marquee_char *next;
  U8 char;
};

class @marquee {
  @marquee_char *text;
  @marquee_char *char;
  I64 ticks;
};

class @player {
  @media media;
  CTask *windowTask;
  CDC **images;
  @marquee marquee;
  I64 pressing_button;
  I64 prev_lb_state;
  I64 prev_rb_state;
  U64 decoder_addr;
};

@player player;

U8 *TEXT_5X6_ROW_1 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ\"@";
U8 *TEXT_5X6_ROW_2 = "0123456789  :()-'!_+\\/[]^&%.=\d#";
U8 *TEXT_5X6_ROW_3 = "   ?*";
U8 *TEXT_5X6_ROW_4 = "abcdefghijklmnopqrstuvwxyz";

U0 Draw5x6TextChar(CDC *dc, I64 x, I64 y, U8 ch) {
  if (ch == ' ')
    return;
  CDC *char_dc = DCNew(5, 6);
  U8 substr[2];
  substr[0] = ch;
  substr[1] = NULL;
  Bool put_char = FALSE;
  if (StrFind(substr, TEXT_5X6_ROW_1)) {
    GrBlot(char_dc, -(5 * (StrFind(substr, TEXT_5X6_ROW_1) - TEXT_5X6_ROW_1)),
           0, IMG_TEXT);
    put_char = TRUE;
  }
  if (StrFind(substr, TEXT_5X6_ROW_2)) {
    GrBlot(char_dc, -(5 * (StrFind(substr, TEXT_5X6_ROW_2) - TEXT_5X6_ROW_2)),
           -6, IMG_TEXT);
    put_char = TRUE;
  }
  if (StrFind(substr, TEXT_5X6_ROW_3)) {
    GrBlot(char_dc, -(5 * (StrFind(substr, TEXT_5X6_ROW_3) - TEXT_5X6_ROW_3)),
           -12, IMG_TEXT);
    put_char = TRUE;
  }
  if (StrFind(substr, TEXT_5X6_ROW_4)) {
    GrBlot(char_dc, -(5 * (StrFind(substr, TEXT_5X6_ROW_4) - TEXT_5X6_ROW_4)),
           0, IMG_TEXT);
    put_char = TRUE;
  }
  if (put_char)
    GrBlot(dc, x, y, char_dc);
  DCDel(char_dc);
}

U0 DrawPlayerMarqueeText(CDC *dc, I64 x, I64 y) {
  I64 pos = 0;
  I64 posX = 0;
  @marquee_char *mchar = player.marquee.char;
  while (pos < 31) {
    Draw5x6TextChar(dc, posX + x, y, mchar->char);
    posX += 5;
    mchar = mchar->next;
    pos++;
  }
}

Bool CheckIfButtonIsHovered(I64 x, I64 y, I64 w, I64 h) {
  if (ms.pos.x >= player.windowTask->pix_left + x &&
      ms.pos.x <= player.windowTask->pix_left + x + w &&
      ms.pos.y >= player.windowTask->pix_top + y &&
      ms.pos.y <= player.windowTask->pix_top + y + h)
    return TRUE;
  return FALSE;
}

U0 DrawPlayerControlsActive(CDC *dc, I64 x, I64 y) {

  CDC *control_dc = DCNew(23, 18);

  if (!ms.lb && player.prev_lb_state) {
    switch (player.pressing_button) {
    case BTN_PREV:
      if (CheckIfButtonIsHovered(x, y, 23, 18)) {
        // player.Prev();
      }
      break;
    case BTN_PLAY:
      if (CheckIfButtonIsHovered(x + (23 * 1), y, 23, 18)) {
        player.media.paused = FALSE;
        player.media.stopped = FALSE;
      }
      break;
    case BTN_PAUSE:
      if (CheckIfButtonIsHovered(x + (23 * 2), y, 23, 18)) {
        player.media.paused = !player.media.paused;
      }
      break;
    case BTN_STOP:
      if (CheckIfButtonIsHovered(x + (23 * 3), y, 23, 18)) {
        player.media.stopped = TRUE;
      }
      break;
    case BTN_NEXT:
      if (CheckIfButtonIsHovered(x + (23 * 4), y, 23, 18)) {
        // player.Next();
      }
      break;
    case BTN_EJECT:
      if (CheckIfButtonIsHovered(x + 121, y + 1, 22, 15)) {
        player.windowTask->user_data = ACTION_PICK_FILE;
      }
    default:
      break;
    }
    player.pressing_button = BTN_NULL;
  }

  if (ms.lb && !player.prev_lb_state) {
    if (CheckIfButtonIsHovered(x, y, 23, 18))
      player.pressing_button = BTN_PREV;
    if (CheckIfButtonIsHovered(x + (23 * 1), y, 23, 18))
      player.pressing_button = BTN_PLAY;
    if (CheckIfButtonIsHovered(x + (23 * 2), y, 23, 18))
      player.pressing_button = BTN_PAUSE;
    if (CheckIfButtonIsHovered(x + (23 * 3), y, 23, 18))
      player.pressing_button = BTN_STOP;
    if (CheckIfButtonIsHovered(x + (23 * 4), y, 23, 18))
      player.pressing_button = BTN_NEXT;
    if (CheckIfButtonIsHovered(x + 121, y + 1, 22, 15))
      player.pressing_button = BTN_EJECT;
  }

  switch (player.pressing_button) {
  case BTN_PREV:
    if (CheckIfButtonIsHovered(x, y, 23, 18)) {
      DCFill(control_dc);
      GrBlot(control_dc, 0, -17, IMG_CBUTTONS);
      GrBlot(dc, x, y, control_dc);
    }
    break;
  case BTN_PLAY:
    if (CheckIfButtonIsHovered(x + (23 * 1), y, 23, 18)) {
      DCFill(control_dc);
      GrBlot(control_dc, -(23 * 1), -17, IMG_CBUTTONS);
      GrBlot(dc, x + (23 * 1), y, control_dc);
    }
    break;
  case BTN_PAUSE:
    if (CheckIfButtonIsHovered(x + (23 * 2), y, 23, 18)) {
      DCFill(control_dc);
      GrBlot(control_dc, -(23 * 2), -17, IMG_CBUTTONS);
      GrBlot(dc, x + (23 * 2), y, control_dc);
    }
    break;
  case BTN_STOP:
    if (CheckIfButtonIsHovered(x + (23 * 3), y, 23, 18)) {
      DCFill(control_dc);
      GrBlot(control_dc, -(23 * 3), -17, IMG_CBUTTONS);
      GrBlot(dc, x + (23 * 3), y, control_dc);
    }
    break;
  case BTN_NEXT:
    if (CheckIfButtonIsHovered(x + (23 * 4), y, 23, 18)) {
      DCFill(control_dc);
      GrBlot(control_dc, -(23 * 4), -17, IMG_CBUTTONS);
      GrBlot(dc, x + (23 * 4), y, control_dc);
    }
    break;
  case BTN_EJECT:
    if (CheckIfButtonIsHovered(x + 121, y + 1, 22, 15)) {
      DCFill(control_dc);
      GrBlot(control_dc, -113, -16, IMG_CBUTTONS);
      control_dc->color = TRANSPARENT;
      GrRect(control_dc, 0, 16, 32, 32);
      GrBlot(dc, x + 121, y + 1, control_dc);
    }
    break;
  default:
    break;
  }

  player.prev_lb_state = ms.lb;
  player.prev_rb_state = ms.rb;

  DCDel(control_dc);
}

U0 DrawPlayerControlsIdle(CDC *dc, I64 x, I64 y) {
  CDC *controls_dc = DCNew(114, 17);
  CDC *eject_dc = DCNew(22, 15);
  GrBlot(controls_dc, 0, 0, IMG_CBUTTONS);
  GrBlot(eject_dc, -113, -1, IMG_CBUTTONS);
  GrBlot(dc, x, y, controls_dc);
  GrBlot(dc, x + 121, y + 1, eject_dc);
  DCDel(controls_dc);
  DCDel(eject_dc);
}

U0 InsertMarqueeTextChar(U8 ch) {
  @marquee_char *pos = player.marquee.text;
  if (!player.marquee.text) {
    player.marquee.text = CAlloc(sizeof(@marquee_char));
    player.marquee.text->char = ch;
    player.marquee.text->next = player.marquee.text;
    return;
  }
  while (pos->next != player.marquee.text)
    pos = pos->next;
  pos->next = CAlloc(sizeof(@marquee_char));
  pos->next->char = ch;
  pos->next->next = player.marquee.text;
}

U0 SetPlayerMarqueeText(U8 *str) {
  player.marquee.text = NULL;
  while (*str) {
    InsertMarqueeTextChar(*str);
    str++;
  }
  player.marquee.char = player.marquee.text;
}

U0 UpdatePlayerMarqueeTextPos() {
  player.marquee.ticks++;
  if (player.marquee.ticks > 6) {
    player.marquee.ticks = 0;
    player.marquee.char = player.marquee.char->next;
  }
}

U0 DecodeMP3Stream() {
  *GCC_FUN_ADDR(U64 *) = player.decoder_addr;

  @drmp3_config config;
  config.channels = 0;
  config.sampleRate = 0;

  *HOLYC_ARG1(U64 *) = player.media.source_data;
  *HOLYC_ARG2(I32 *) = player.media.source_len;
  *HOLYC_ARG3(U64 *) = &config;
  *HOLYC_ARG4(U64 *) = &player.media.pcm_frames;
  *HOLYC_ARG5(U64 *) = NULL;
  asm {
        MOV RDI, [HOLYC_ARG1]
        MOV RSI, [HOLYC_ARG2]
        MOV RDX, [HOLYC_ARG3]
        MOV RCX, [HOLYC_ARG4]
        MOV R8, [HOLYC_ARG5]
        MOV RAX, [GCC_FUN_ADDR]
        CLI
        CALL RAX
        STI
  }
  player.media.channels = config.channels;
  player.media.sampleRate = config.sampleRate;
  player.media.pcm_data = pcm_buffer_ptr;
}

U0 CalculateMediaRunTime() {
  player.media.runtime_mins =
      (player.media.pcm_frames / player.media.sampleRate) / 60;
  player.media.runtime_secs =
      (player.media.pcm_frames / player.media.sampleRate) % 60;
}

U0 ParseID3() {
  StrCpy(&player.media.title, "");
  StrCpy(&player.media.artist, "");
  StrCpy(&player.media.album, "");
  StrCpy(&player.media.year, "");
  @id3v1 *tag = player.media.source_data + player.media.source_len - 128;
  if (MemCmp(tag->header, "TAG", 3))
    return;
  StrCpy(&player.media.title, tag->title);
  StrCpy(&player.media.artist, tag->artist);
  StrCpy(&player.media.album, tag->album);
  StrCpy(&player.media.year, tag->year);
}

U0 PlayerTask() {
  while (1) {
    if (FifoI64Cnt(Audio.output[0].data)) {
      if (player.media.pcm_data && !player.media.paused &&
          !player.media.stopped)
        @ac97_process_audio;
    }
    Sleep(1);
  }
}

U0 OpenAndPlayFile(U8 *filename) {
  if (!FileFind(filename)) {
    PopUpOk("Error: File not found."); // FIXME - this will probably freeze,
                                       // can't do PopUp in DrawIt task
    return;
  }
  player.media.source_data = FileRead(filename, &player.media.source_len);
  player.media.source_type = SRC_TYPE_MP3;

  switch (player.media.source_type) {
  case SRC_TYPE_MP3:
    ParseID3;
    DecodeMP3Stream;
    CalculateMediaRunTime;
    break;
  default:
    PopUpOk(
        "Error: Unsupported media type."); // FIXME - this will probably freeze,
                                           // can't do PopUp in DrawIt task
    return;
    break;
  }

  U8 marquee_buf[32];
  StrPrint(marquee_buf, "1. %s - %s (%02d:%02d) *** ", player.media.artist,
           player.media.title, player.media.runtime_mins,
           player.media.runtime_secs);
  SetPlayerMarqueeText(marquee_buf);

  FifoI64Flush(Audio.output[0]);
  @audio_play_sfx(player.media.pcm_data, player.media.pcm_frames);
  Audio.output_frames[0] = 0;

  player.media.stopped = FALSE;
  player.media.paused = FALSE;
}

U0 UpdatePlayerActions() {
  if (player.windowTask->dbg_task) { // Was a new track selected? If so, let's
                                     // try to open it!
    if (StrCmp(player.windowTask->dbg_task, "")) {
      OpenAndPlayFile(player.windowTask->dbg_task);
    }
    player.windowTask->dbg_task = NULL;
  }
}

U0 DrawPlayerTimeElapsed(CDC *dc) {
  if (player.media.stopped)
    return;

  if (player.media.paused && !Blink(.5))
    return;

  I64 i;

  U8 min_buf[3];
  U8 sec_buf[3];
  min_buf[2] = NULL;
  sec_buf[2] = NULL;
  StrPrint(min_buf, "%02d",
           (Audio.output_frames[0] / player.media.sampleRate) / 60);
  StrPrint(sec_buf, "%02d",
           (Audio.output_frames[0] / player.media.sampleRate) % 60);

  CDC *num_dc = DCNew(9, 13);

  for (i = 0; i < 2; i++) {
    DCFill(num_dc);
    GrBlot(num_dc, -(9 * (min_buf[i] - '0')), 0, IMG_NUMBERS);
    GrBlot(dc, 50 + (12 * i), 27, num_dc);
  }

  for (i = 0; i < 2; i++) {
    DCFill(num_dc);
    GrBlot(num_dc, -(9 * (sec_buf[i] - '0')), 0, IMG_NUMBERS);
    GrBlot(dc, 81 + (12 * i), 27, num_dc);
  }

  DCDel(num_dc);
}

U0 DrawPlayerPlayPauseStopped(CDC *dc) {
  CDC *state_dc = DCNew(9, 9);

  if (!player.media.paused && !player.media.stopped) {
    DCFill(state_dc);
    GrBlot(state_dc, 0, 0, IMG_PLAYPAUS);
    GrBlot(dc, 28, 28, state_dc);
  }

  if (player.media.paused) {
    DCFill(state_dc);
    GrBlot(state_dc, -9, 0, IMG_PLAYPAUS);
    GrBlot(dc, 28, 28, state_dc);
  }

  if (player.media.stopped) {
    DCFill(state_dc);
    GrBlot(state_dc, -18, 0, IMG_PLAYPAUS);
    GrBlot(dc, 28, 28, state_dc);
  }

  DCDel(state_dc);
}

U0 DrawPlayer(CTask *, CDC *dc) {
  GrBlot(dc, 3, 2, IMG_MAIN);
  UpdatePlayerActions;
  UpdatePlayerMarqueeTextPos;
  DrawPlayerMarqueeText(dc, 113, 29);
  DrawPlayerPlayPauseStopped(dc);
  DrawPlayerTimeElapsed(dc);
  DrawPlayerControlsActive(dc, 22, 91);
}

U0 InitPlayer() {
  MemSet(&player, sizeof(@player), NULL);
  player.windowTask = User;
  XTalkWait(
      player.windowTask,
      "DocClear; while (1) { switch(Fs->user_data) { case 1: "
      "Fs->dbg_task = PopUpPickFile(\"T:/Music/\"); Fs->user_data = NULL; "
      "break; default: break; };"
      "Sleep(1); };\n");
  player.windowTask->win_width = 35;
  WinHorz((TEXT_COLS / 2) - (player.windowTask->win_width / 2),
          (TEXT_COLS / 2) - (player.windowTask->win_width / 2) +
              (player.windowTask->win_width - 1),
          player.windowTask);
  player.windowTask->win_height = 15;
  WinVert((TEXT_ROWS / 2) - (player.windowTask->win_height / 2),
          (TEXT_ROWS / 2) - (player.windowTask->win_height / 2) +
              (player.windowTask->win_height - 1),
          player.windowTask);
  StrCpy(player.windowTask->task_title, "...TOSamp...");

  player.images = CAlloc(sizeof(CDC *) * 32);
  IMG_MAIN = PNGRead("T:/Images/MAIN.png");
  IMG_CBUTTONS = PNGRead("T:/Images/CBUTTONS.png");
  IMG_TEXT = PNGRead("T:/Images/TEXT.png");
  IMG_NUMBERS = PNGRead("T:/Images/NUMBERS.png");
  IMG_PLAYPAUS = PNGRead("T:/Images/PLAYPAUS.png");

  DrawPlayerControlsIdle(IMG_MAIN, 19, 90);
  // the control buttons are 23x18

  SetPlayerMarqueeText(
      "Welcome to TosAMP - MP3 Music Player for TempleOS *** ");

  player.media.stopped = TRUE;
  player.decoder_addr =
      get_symbol_address("drmp3_open_memory_and_read_pcm_frames_s16");
  player.windowTask->draw_it = &DrawPlayer;

  Spawn(&PlayerTask, , "TOSamp Player Task", 1);
}
