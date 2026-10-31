// Port of NSV13 tgui/interfaces/ShipLoadout.js (Inferno) to TGMC React/TS. Mechanical conversion, not compiled.
import { useBackend, useLocalState } from '../backend';
import { Button, Section } from 'tgui-core/components';
import { Window } from '../layouts';

export const ShipLoadout = (props: any) => {
  const { act, data } = useBackend<any>();
  return (
    <Window
     
      theme="syndicate"
      width={500}
      height={500}>
      <Window.Content scrollable>
        <Section title="Info:">
          <p>Powergrid Scan: Complete. The device has identified several unpowered subsystems, though the power-core can only activate one. Choose wisely!</p>
        </Section>
        <Section title="Detected Subsystems:">
          {Object.keys(data.categories).map(key => {
            let value = data.categories[key];
            return (
              <Section key={key} title={value.name} buttons={
                <Button
                  content="Select"
                  icon="check-circle"
                  onClick={() => act('select', { target_id: value.id })} />
              }>
                <p>{value.desc}</p>
              </Section>
            );
          })}
        </Section>
      </Window.Content>
    </Window>
  );
};
