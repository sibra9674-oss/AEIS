// Port of NSV13 tgui/interfaces/SalvageConsole.js (Inferno) to TGMC React/TS. Mechanical conversion, not compiled.
import { useBackend, useLocalState } from '../backend';
import { Button, Section, ProgressBar } from 'tgui-core/components';
import { Window } from '../layouts';

export const SalvageConsole = (props: any) => {
  const { act, data } = useBackend<any>();
  return (
    <Window
     
      theme="hackerman"
      width={600}
      height={800}>
      <Window.Content scrollable>
        <br />
        {!!data.salvage_target && (
          <Section title={"Currently maintaining: " + data.salvage_target_name} buttons={
            <Button
              icon="bullseye"
              content="Release Hammerlock"
              color="average"
              tooltip="Stop scrambling this ship's defenses. This will cause any forces boarding it to be killed."
              onClick={() => act('stop_salvage')}
            />
          } >
            <ProgressBar
              value={(data.salvage_target_integrity / data.salvage_target_max_integrity * 100) * 0.01}
              ranges={{
                good: [0.50, Infinity],
                average: [0.15, 0.50],
                bad: [-Infinity, 0.15],
              }} />
          </Section>

        )}
        <Section title="Available Salvage Targets:">
          {Object.keys(data.ships).map(key => {
            let value = data.ships[key];
            return (
              <Section key={key} title={value.name} buttons={
                <Button
                  content="Establish Hammerlock"
                  icon="anchor"
                  onClick={() => act('salvage', { target: value.id })} />
              }>
                {value.desc}
              </Section>
            );
          })}
        </Section>

      </Window.Content>
    </Window>
  );
};
