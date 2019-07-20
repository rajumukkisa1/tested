import { nextView } from '../store';
import { MR_ID, MR_ID_BUTTON } from './constants';
import { clearNote, postError } from './note';
import singleForm from './single_line_form';
import { escape, selectMrBox, selectRemember } from './utils';
import { addForm } from './wrapper';

/* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
const mrLabel = `Enter your merge request ID`;
/* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
const mrRememberText = `Remember this number`;

const texts = {
  labelText: mrLabel,
  rememberText: mrRememberText,
};

const mrForm = singleForm({
  inputId: MR_ID,
  buttonId: MR_ID_BUTTON,
  autocomplete: '',
  type: 'number',
  placeholder: 'e.g., 321',
  ...texts,
});

const storeMR = (id, state) => {
  const { localStorage } = window;
  const rememberMe = selectRemember().checked;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  try {
    if (rememberMe) {
      localStorage.setItem('mergeRequestId', id);
    }
  } finally {
    state.mergeRequestId = id;
  }
};

const addMr = state => {
  // Clear any old errors
  clearNote(MR_ID);

  const mrNumber = selectMrBox().value;

  if (!mrNumber) {
    /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
    postError('Please enter your merge request ID number.', MR_ID);
    return;
  }

  storeMR(escape(mrNumber), state);
  addForm(nextView(state, MR_ID));
};

export { addMr, mrForm, storeMR };
